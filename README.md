# Motora

Suivi d'entretien automobile : kilométrage, échéances d'entretien, pièces
d'usure, réparations, pleins de carburant, garages et papiers administratifs
(vignette, assurance, contrôle technique, carte grise), avec rappels locaux.

Flutter + Supabase (Postgres, Auth, Storage), état géré avec Riverpod.

## Démarrer

Les identifiants Supabase sont passés au build, jamais commités :

```bash
cp env.example.json env.json
```

Renseigne `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans `env.json`, puis :

```bash
flutter run --dart-define-from-file=env.json
```

Sans identifiants, l'app démarre sur un écran expliquant la configuration
manquante plutôt que de planter.

## Base de données

Applique les migrations de `supabase/migrations/` dans l'ordre, puis
`supabase/storage_buckets.sql` (les buckets ne sont pas dans une migration).

```bash
supabase db push
```

## Vérifier

```bash
flutter analyze && flutter test
```

## Architecture

| Dossier | Rôle |
|---|---|
| `lib/models/` | DTO ↔ lignes Postgres (`fromJson` / `toInsert`) |
| `lib/services/` | Accès Supabase, et la logique métier pure (`PredictionService`, `FuelService`) |
| `lib/providers/` | Graphe Riverpod : données, mutations, réglages, session |
| `lib/screens/` | Écrans et bottom sheets |
| `lib/widgets/` | Composants réutilisables |
| `lib/core/` | Thème, formateurs, constantes, mapping d'erreurs |

Deux points valent d'être connus avant de toucher au métier :

- **Les prévisions sont ancrées sur le dernier entretien enregistré**, jamais
  sur le compteur actuel. Un type sans ancre ne produit aucune prévision et
  remonte `needsSetup` — l'app demande l'information au lieu d'afficher 0 %.
- **`maintenance_types.last_done_km` / `last_done_date` sont dérivées** de
  `maintenance_history` par un trigger (migration 0005). Ne les écris pas
  depuis le client.
