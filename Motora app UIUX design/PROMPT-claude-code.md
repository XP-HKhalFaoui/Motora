# Prompt Claude Code — Application "Motora" (Carnet Auto)

> Copie-colle ce prompt à Claude Code. Il combine le schéma de données/backend et le design system visuel des maquettes Motora.

---

Crée une application mobile **Flutter** nommée **"Motora"** (carnet d'entretien automobile), connectée à **Supabase**. Utilise **Riverpod** pour la gestion d'état. Cible **Android en priorité** (Material 3), iOS compatible.

## 1. Objectif

Suivre l'entretien complet d'un ou plusieurs véhicules : kilométrage, vidanges, durée de vie des pièces d'usure, réparations, documents administratifs annuels (assurance, vignette, contrôle technique) et rappels automatiques. Priorité produit : **lire en un coup d'œil « qu'est-ce qui est urgent maintenant »**.

## 2. Stack technique

- State management : **Riverpod** (providers + notifiers)
- Backend : **Supabase** (Auth email/mot de passe + magic link, Postgres, Storage, Realtime optionnel)
- Notifications locales : `flutter_local_notifications`
- Fichiers/scans : `image_picker` + Supabase Storage
- Graphiques (évolution km) : `fl_chart`
- Polices : `google_fonts` (Manrope + Space Grotesk)
- Icônes : Material Symbols

### Arborescence
```
lib/
 ├── main.dart
 ├── core/            supabase_client.dart, theme.dart, constants.dart
 ├── models/          vehicle, mileage_log, maintenance_type, maintenance_history, admin_document
 ├── providers/       vehicle_provider, maintenance_provider, notification_provider
 ├── services/        supabase_service, prediction_service, notification_service
 ├── screens/         onboarding, home, vehicle_detail, maintenance, history, admin_documents, notifications, settings
 └── widgets/         km_gauge, maintenance_card, document_card, alert_banner, bottom_nav
```

## 3. Schéma Supabase (PostgreSQL) — applique-le avec RLS

```sql
create table vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  name text not null, brand text, model text, year int,
  plate_number text, current_km int not null default 0,
  purchase_date date, photo_url text,
  created_at timestamptz default now()
);
create table mileage_logs (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  km int not null, recorded_at timestamptz default now(), note text
);
create table maintenance_types (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  label text not null, interval_km int, interval_months int,
  last_done_km int, last_done_date date, icon text
);
create table maintenance_history (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  maintenance_type_id uuid references maintenance_types(id),
  title text not null, description text, km int, cost numeric(10,2),
  garage_name text, done_at date not null, invoice_url text,
  created_at timestamptz default now()
);
create table admin_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  doc_type text not null, year int not null, issued_date date,
  expiry_date date not null, file_url text,
  status text default 'pending', created_at timestamptz default now()
);
create table notifications (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references vehicles(id) on delete cascade,
  related_table text, related_id uuid, title text not null, body text,
  trigger_date timestamptz not null, is_sent boolean default false
);
```
- **RLS** activé sur toutes les tables : policy `user_id = auth.uid()` (via jointure sur `vehicles.user_id` pour les tables enfants).
- **Storage buckets** : `vehicle-photos`, `invoices`, `admin-documents`.

## 4. Logique métier

**Moyenne km/mois** (glissante 3–6 derniers mois de `mileage_logs`) :
`moyenne_km_mois = (km_actuel - km_il_y_a_N_mois) / N`

**Prédiction prochaine révision** (par `maintenance_type`) :
```
km_restants   = (last_done_km + interval_km) - current_km
mois_restants = km_restants / moyenne_km_mois
date_estimee  = aujourd'hui + mois_restants
```
Affichage : « ≈ dans 1 800 km / environ 2 mois ».

**Statut couleur** d'une pièce : vert (>50 % de marge), orange/ambre (10–50 %), rouge (<10 % ou dépassé).

**Notifications** déclenchées quand : `km_restants < 500` OU `date_estimee - aujourd'hui < 30 j` OU `expiry_date - aujourd'hui < 30 j`. Recalcul à chaque ouverture d'app via `flutter_local_notifications`.

## 5. Design system Motora (à reproduire fidèlement)

**Thème sombre par défaut + thème clair** (bascule dans Réglages). Ambiance : sobre, technique mais chaleureuse.

### Couleurs — thème sombre
| Rôle | Hex |
|---|---|
| Fond app | `#0E1520` |
| Surface / carte | `#17202E` |
| Surface élevée | `#1E2A3A` |
| Barre de nav | `#0C121B` |
| Texte principal | `#EAF0F7` |
| Texte secondaire | `#8695A8` |
| Texte discret | `#5D6B7E` |
| Filet / bordure | `rgba(255,255,255,0.07)` |
| Primaire (bleu) | `#4C8DFF` |
| Alerte / FAB (orange) | `#FF8A3D` |
| Statut vert | `#35C88A` |
| Statut ambre | `#F5B23D` |
| Statut rouge | `#FF5D5D` |

### Couleurs — thème clair
Fond `#EEF1F6` · surface `#FFFFFF` · texte `#16202E` · secondaire `#5E6B7D` · bordure `rgba(18,28,42,0.08)` · bleu `#2F72E8` · orange `#F2732A` · vert `#1FA971` · ambre `#C8871B` · rouge `#E23B3B`.

### Typographie
- **Manrope** : UI, labels, corps de texte (400/500/600/700/800).
- **Space Grotesk** : titres d'écran, wordmark « Motora », et **tous les chiffres techniques** (kilométrage, coûts, compteurs) pour un rendu odomètre.
- Labels de section : 12–13 px, MAJUSCULES, `letter-spacing` ~0.5px, couleur secondaire.

### Formes & style
- Rayons : cartes 16–22 px, boutons 14–15 px, pastilles/chips 8–10 px, badges statut 99 px (pill).
- Cartes : surface + bordure filet 1px ; en thème clair, ombre douce `0 8px 24px -16px rgba(60,72,92,.5)`.
- Cartes d'entretien : **bordure gauche colorée de 3px** selon le statut (rouge/ambre/vert).
- FAB central orange (`#FF8A3D`), rayon 20px, ancré au-dessus de la bottom nav.
- Barres de progression : piste = fond app, remplissage = couleur de statut, hauteur 7px, rayon 99px.
- Jauge km : anneau circulaire (conic gradient, ~206px), portion bleue = progression, centre = valeur km en Space Grotesk + moyenne mensuelle.
- Placeholders photo/scan : motif rayé diagonal en attendant les vraies images.
- **Pas d'emoji.**

### Chrome Android
Status bar (heure + réseau/wifi/batterie), bottom navigation Material à 5 entrées avec **encoche centrale pour le FAB** : Accueil · Entretien · Docs · Alertes (badge point rouge si non lus) · [Réglages accessible depuis l'avatar]. Barre de gestes (pill) en bas.

## 6. Écrans à implémenter (dans l'ordre)

1. **Onboarding / Connexion** — wordmark Motora, illustration, champs email + mot de passe, bouton « Se connecter », bouton secondaire « Recevoir un lien magique », lien « Créer un compte ». (Supabase Auth)
2. **Accueil** — salutation + avatar ; bannière **alertes prioritaires** en orange en haut (liste triée par urgence, point rouge/ambre + reste km/jours) ; cartes véhicules (photo, plaque, km en grand, moyenne mensuelle, chips d'échéance colorées) ; bottom nav + FAB.
3. **Détail véhicule** — en-tête (nom, plaque, marque·année) ; **jauge km circulaire** + bouton « Mettre à jour le km » (ajoute une entrée `mileage_logs`) ; 2 stats (coût total, nb interventions) ; liste « Prochaines échéances » avec barres de progression colorées et estimation « dans X km / Y mois ».
4. **Entretien / Pièces** — sélecteur segmenté par véhicule ; 3 compteurs (urgent/à surveiller/OK) ; liste des `maintenance_types` (icône, label, dernière opération, barre de progression + bordure gauche colorée, reste km en badge).
5. **Historique réparations** — 2 stats (total 12 mois, nb interventions) ; **timeline verticale** (points + trait) : date, titre, km, garage, coût, chip « Facture ».
6. **Documents administratifs** — sélecteur d'année (pills) ; cartes par document (miniature scan à gauche, type + icône, statut pill coloré, date d'échéance) ; bouton « Scanner un document » (upload Storage).
7. **Ajout rapide** — **bottom sheet** par-dessus l'accueil assombri : grille 2×2 (Relevé km, Réparation, Document, Plein/dépense) avec icônes teintées.
8. **Notifications** — groupées « Aujourd'hui » / « Cette semaine » ; items avec icône teintée par type, titre, corps, horodatage, point non-lu ; action « Tout lire ».
9. **Paramètres** — carte profil ; section Véhicules (liste + « Ajouter ») ; Alertes & seuils (seuil km = 500, seuil échéance = 30 j, toggle push) ; Préférences (unité km/miles, toggle thème sombre) ; « Se déconnecter ».

## 7. Données de démo (seed)

- **Clio 4** — Renault, 2018, Diesel, AB-123-CD, 112 480 km, +1 240 km/mois. Vidange dans 320 km (rouge), plaquettes avant dans 4 200 km (ambre), CT dans 3 mois (vert).
- **Golf 7** — Volkswagen, 2016, Essence, CD-456-EF, 98 200 km, +820 km/mois. Assurance expire dans 12 jours (ambre).
- Historique Clio 4 : Vidange+filtre (12/03/2026, 110 200 km, Norauto, 89 €), Plaquettes avant (05/01/2026, 108 900 km, Speedy, 145 €), Pneus ×2 (20/10/2025, 105 400 km, Euromaster, 220 €).

## 8. Ordre de livraison

1. Auth Supabase + thème (sombre/clair) + navigation.
2. CRUD véhicules + mise à jour km avec historique.
3. Écran Entretien + `prediction_service` (calcul auto prochaine révision).
4. Historique réparations + upload facture (Storage).
5. Documents administratifs + upload scan + statut/échéance.
6. Notifications locales (< 30 j ou < 500 km).

Applique le schéma SQL avec RLS sur toutes les tables. Respecte fidèlement les couleurs, la typo et les composants du design system ci-dessus.
