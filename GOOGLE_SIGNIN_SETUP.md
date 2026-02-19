# Google Sign-In Setup (Supabase + Flutter)

## Summary of Changes

### 1. Supabase Initialization
- **File:** `packages/shared/lib/api/supabase_client.dart`
- Added `authRedirectUrl` for OAuth callback deep link.

- **File:** `apps/mobile/lib/main.dart`
- Passes `authRedirectUrl: 'com.meda.app://login-callback/'` to Supabase config.
- Adds auth state listener to sync profile and refresh router on login.

### 2. Auth Repository
- **File:** `apps/mobile/lib/features/auth/data/supabase_auth_repository.dart`
- `signInWithGoogle()` and `signInWithApple()` now use `redirectTo: 'com.meda.app://login-callback/'`.

### 3. Android Deep Linking
- **File:** `apps/mobile/android/app/src/main/AndroidManifest.xml`
- Added intent-filter for `com.meda.app://login-callback`.

### 4. iOS Deep Linking
- **File:** `apps/mobile/ios/Runner/Info.plist`
- Added `CFBundleURLTypes` with scheme `com.meda.app`.

### 5. Profile Sync
- **File:** `apps/mobile/lib/features/auth/data/profile_sync_service.dart` (new)
- Syncs `id`, `email`, `full_name`, `avatar_url` to `profiles` after OAuth/login.

### 6. Router & Auth Protection
- **File:** `apps/mobile/lib/app/router.dart`
- Added `redirect` to send unauthenticated users to `/login`.
- Redirects from `/login` and `/signup` to `/home` when logged in.
- Uses `refreshListenable` to react to auth changes (e.g. after OAuth callback).

### 7. Reusable Google Sign-In Button
- **File:** `apps/mobile/lib/core/widgets/google_sign_in_button.dart` (new)
- Reusable `GoogleSignInButton` widget.

### 8. Database Migration
- **File:** `supabase/migrations/016_profiles_avatar.sql` (new)
- Adds `avatar_url` to `profiles`.
- Updates `handle_new_user` trigger for OAuth metadata (`full_name`, `avatar_url`).
- Adds insert policy for profile upsert.

---

## Supabase Dashboard Configuration

1. **Authentication → URL Configuration**
   - Add to Redirect URLs: `com.meda.app://login-callback/`

2. **Authentication → Providers → Google**
   - Enable Google provider.
   - Use Client ID and Client Secret from Google Cloud Console.

---

## Run the Migration

```bash
# In Supabase project directory
supabase db push
```

Or run `016_profiles_avatar.sql` in Supabase SQL Editor.

---

## OAuth Flow

1. User taps "تسجيل الدخول بـ Google".
2. App calls `signInWithOAuth(OAuthProvider.google, redirectTo: 'com.meda.app://login-callback/')`.
3. Browser opens for Google sign-in.
4. User completes sign-in; Supabase redirects to `com.meda.app://login-callback/...`.
5. App opens via deep link; Supabase parses tokens and restores session.
6. `onAuthStateChange` fires → profile sync runs → router redirects to `/home`.
