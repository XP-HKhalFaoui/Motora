# Conception — App "Carnet Auto" (Flutter + Supabase)

## 1. Objectif de l'app

Application mobile personnelle pour suivre l'entretien complet d'un ou plusieurs véhicules :
kilométrage, vidanges, durée de vie des pièces, réparations, papiers administratifs annuels
(vignette, assurance, contrôle technique), et rappels automatiques.

---

## 2. Fonctionnalités (mapping de ta demande)

| Ta demande | Fonctionnalité |
|---|---|
| km, vidange | Suivi kilométrage + historique vidanges avec calcul auto de la prochaine |
| durée de vie pièce | Suivi des pièces d'usure (kit chaîne/distribution, plaquettes, pneus, batterie, filtre) avec seuils km/temps |
| suivi réparation | Historique des interventions (date, km, garage, coût, pièces changées, photo facture) |
| suivi papier + vignette par année | Module "Documents administratifs" avec échéance annuelle par type et par année |
| scanner général par année | Rappel "contrôle technique / visite technique" annuel + upload du PV scanné |
| notification | Notifications locales + push (Supabase + Edge Function ou juste local notifications) |
| calcul prochaine révision selon km moyen mensuel | Algorithme prédictif basé sur la moyenne km/mois glissante |

---

## 3. Modèle de données (Supabase / PostgreSQL)

```sql
-- Utilisateurs gérés par Supabase Auth (auth.users)

create table vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  name text not null,             -- "Clio 4", "Voiture femme"...
  brand text,
  model text,
  year int,
  plate_number text,
  current_km int not null default 0,
  purchase_date date,
  photo_url text,
  created_at timestamptz default now()
);

-- Historique des relevés kilométriques (sert au calcul de la moyenne mensuelle)
create table mileage_logs (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  km int not null,
  recorded_at timestamptz default now(),
  note text
);

-- Types de pièces / opérations d'entretien (référentiel)
create table maintenance_types (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  label text not null,            -- "Vidange", "Kit chaîne", "Plaquettes avant"...
  interval_km int,                -- ex: 10000
  interval_months int,            -- ex: 12
  last_done_km int,
  last_done_date date,
  icon text
);

-- Historique réel des interventions / réparations effectuées
create table maintenance_history (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  maintenance_type_id uuid references maintenance_types(id),
  title text not null,
  description text,
  km int,
  cost numeric(10,2),
  garage_name text,
  done_at date not null,
  invoice_url text,               -- photo/pdf facture (Supabase Storage)
  created_at timestamptz default now()
);

-- Documents administratifs annuels (vignette, assurance, contrôle technique...)
create table admin_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  doc_type text not null,         -- "vignette", "assurance", "controle_technique"
  year int not null,
  issued_date date,
  expiry_date date not null,
  file_url text,                  -- scan/photo du document
  status text default 'pending',  -- pending / valid / expired
  created_at timestamptz default now()
);

-- Notifications planifiées
create table notifications (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  related_table text,             -- 'maintenance_types' | 'admin_documents'
  related_id uuid,
  title text not null,
  body text,
  trigger_date timestamptz not null,
  is_sent boolean default false
);
```

**Row Level Security (RLS)** : activer sur toutes les tables, policy `user_id = auth.uid()`
(via jointure sur `vehicles.user_id` pour les tables enfants).

**Storage buckets Supabase** : `vehicle-photos`, `invoices`, `admin-documents`.

---

## 4. Logique métier clé

### 4.1 Calcul de la moyenne kilométrique mensuelle
```
moyenne_km_mois = (km_actuel - km_il_y_a_N_mois) / N
```
→ basé sur les entrées de `mileage_logs` des 3 à 6 derniers mois (glissant).

### 4.2 Prédiction de la prochaine révision
Pour chaque `maintenance_type` :
```
km_restants = (last_done_km + interval_km) - current_km
mois_restants = km_restants / moyenne_km_mois
date_estimee = aujourd'hui + mois_restants
```
Affiche : "≈ dans 1 800 km / environ 2 mois (mi-septembre)".

### 4.3 Notifications
Déclenchées quand :
- km_restants < seuil (ex: 500 km)
- OU date_estimee - aujourd'hui < 30 jours
- OU document admin (`admin_documents.expiry_date`) - aujourd'hui < 30 jours

Implémentation : `flutter_local_notifications` pour les rappels locaux programmés
(recalculés à chaque ouverture d'app ou via un job planifié léger).

---

## 5. Architecture technique Flutter

```
lib/
 ├── main.dart
 ├── core/
 │   ├── supabase_client.dart
 │   ├── theme.dart
 │   └── constants.dart
 ├── models/
 │   ├── vehicle.dart
 │   ├── mileage_log.dart
 │   ├── maintenance_type.dart
 │   ├── maintenance_history.dart
 │   └── admin_document.dart
 ├── providers/            (Riverpod)
 │   ├── vehicle_provider.dart
 │   ├── maintenance_provider.dart
 │   └── notification_provider.dart
 ├── services/
 │   ├── supabase_service.dart
 │   ├── prediction_service.dart   (calcul révision)
 │   └── notification_service.dart
 ├── screens/
 │   ├── home/
 │   ├── vehicle_detail/
 │   ├── maintenance/
 │   ├── admin_documents/
 │   ├── history/
 │   └── settings/
 └── widgets/
     ├── km_gauge.dart
     ├── maintenance_card.dart
     └── document_card.dart
```

**Stack recommandée** :
- State management : **Riverpod**
- Backend : **Supabase** (Auth, Postgres, Storage, Realtime optionnel)
- Notifications locales : `flutter_local_notifications`
- Gestion fichiers/scans : `image_picker` + `supabase_storage`
- Graphiques (évolution km) : `fl_chart`

---

## 6. Écrans à concevoir (pour Claude Design)

1. **Onboarding / Login** (Supabase Auth email ou magic link)
2. **Accueil** : liste des véhicules, jauge km actuel, alertes prioritaires en haut
3. **Détail véhicule** : km actuel + bouton "mettre à jour le km", résumé des prochaines échéances (vidange, pièces, papiers)
4. **Entretien / Pièces** : liste des `maintenance_types` avec barre de progression (km restants) et statut couleur (vert/orange/rouge)
5. **Historique réparations** : timeline des interventions avec coût, garage, facture
6. **Documents administratifs** : cartes par année (vignette, assurance, contrôle technique) avec date d'expiration et scan
7. **Ajout rapide** (FAB) : ajouter km, ajouter réparation, ajouter document
8. **Notifications** : centre de notifications/rappels
9. **Paramètres** : gérer véhicules, seuils d'alerte, unités

---

## 7. Prompt prêt à copier-coller pour Claude Code

```
Crée une application Flutter "Carnet Auto" connectée à Supabase.
Utilise Riverpod pour la gestion d'état.
Structure de données : vehicles, mileage_logs, maintenance_types,
maintenance_history, admin_documents, notifications (voir schéma SQL joint).
Fonctionnalités à implémenter dans l'ordre :
1. Auth Supabase (email/mot de passe)
2. CRUD véhicules + mise à jour km avec historique
3. Écran entretien avec calcul automatique de la prochaine révision
   (basé sur la moyenne km/mois des 3-6 derniers mois)
4. Historique des réparations avec upload de facture (Supabase Storage)
5. Documents administratifs annuels avec upload de scan et date d'expiration
6. Notifications locales pour échéances à moins de 30 jours ou 500 km
Applique le schéma SQL fourni avec RLS activé sur toutes les tables.
```

## 8. Prompt prêt à copier-coller pour Claude Design (UI)

```
Conçois l'interface d'une app mobile Flutter "Carnet Auto" (gestion d'entretien
automobile). Style : sobre, technique mais chaleureux, palette bleu/gris foncé
avec accents orange pour les alertes.
Écrans à designer : Accueil (liste véhicules + alertes), Détail véhicule (jauge km),
Entretien (barres de progression par pièce, code couleur vert/orange/rouge),
Historique réparations (timeline), Documents administratifs (cartes par année),
Ajout rapide (bottom sheet), Notifications.
Priorité : lisibilité rapide de "qu'est-ce qui est urgent maintenant".
```

---

## 9. Prochaines étapes suggérées

- Valider ce schéma de données puis le donner directement à Claude Code pour générer le projet Flutter.
- Donner la section 6 + le prompt de la section 8 à Claude Design pour les maquettes.
- Ajouter plus tard : multi-véhicules partagés (famille), export PDF de l'historique, mode hors-ligne.
