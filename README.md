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

## Publier (Android)

Le build release retombe sur les clés de debug tant que `android/key.properties`
est absent — pratique en local, mais un APK signé ainsi est refusé par le
Play Store. Pour signer pour de vrai, génère un keystore :

```bash
keytool -genkey -v -keystore ~/motora-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias motora
```

Puis crée `android/key.properties` (gitignoré, à ne jamais commiter) :

```properties
storePassword=…
keyPassword=…
keyAlias=motora
storeFile=/Users/toi/motora-release.jks
```

```bash
flutter build appbundle --release --dart-define-from-file=env.json
```

Garde une sauvegarde du `.jks` : le perdre rend toute mise à jour de l'app
impossible.

## Icône et splash

L'artwork est provisoire et généré par script. Pour le remplacer, dépose un
PNG 1024×1024 en `assets/icon/icon.png` puis :

```bash
dart run flutter_launcher_icons && dart run flutter_native_splash:create
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
