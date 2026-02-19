# Mada App Monorepo

Flutter monorepo for:
- `apps/mobile`: iOS/Android/iPad learning app (Arabic-first, RTL)
- `apps/admin`: Flutter Web admin dashboard
- `packages/shared`: shared design system, localization, models, API clients

## Prerequisites
- Flutter (stable)
- Dart >= 3.3
- Melos (`dart pub global activate melos`)
- Supabase project + keys
- Firebase project (for FCM)
- RevenueCat account (for subscriptions)

## Quick Start
1. Set env files (dev/staging/prod):
   - `cp apps/mobile/.env.example apps/mobile/.env.dev`
   - `cp apps/admin/.env.example apps/admin/.env.dev`
2. Install dependencies:
   - `melos bootstrap`
3. Generate code:
   - `melos run build`
4. Run mobile:
   - `cd apps/mobile && flutter run --dart-define=ENV=dev`
5. Run admin:
   - `cd apps/admin && flutter run -d chrome --dart-define=ENV=dev`

## Supabase
SQL migrations are in `supabase/migrations`. Apply them in Supabase SQL editor.
Seed data is in `supabase/seed.sql`.

## Firebase (FCM)
1. Create Firebase project and add iOS/Android apps.
2. Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
3. Ensure APNs is configured for iOS push.

## RevenueCat
1. Create a project and add iOS/Android apps.
2. Copy public API key to `REVENUECAT_API_KEY` in env files.

## Scripts (Melos)
- `melos run build` → code generation (freezed/json_serializable)
- `melos run analyze` → analyze all packages
- `melos run test` → tests

## Project Structure
```
/apps
  /mobile
  /admin
/packages
  /shared
/supabase
  /migrations
  seed.sql
```

