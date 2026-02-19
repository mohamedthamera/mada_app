# Lifetime IAP Setup & Testing

This document covers the **Lifetime (one-time) payment system** for the Flutter courses app: Apple In-App Purchase (iOS), Google Play Billing (Android), and Supabase backend with **mock** and **real** modes.

---

## 1. Global toggle: `PAYMENT_MODE`

- **`mock`** (default): No store APIs. Simulates a successful purchase and calls the Supabase Edge Function with `mock: true`. Only the **admin email** (see `ADMIN_EMAIL` below) is granted lifetime access.
- **`real`**: Uses Apple IAP and Google Play Billing; receipts/tokens are verified by the Edge Function.

### How to set

**Option A – dart-define (recommended):**

```bash
# Mock (development)
flutter run --dart-define=PAYMENT_MODE=mock

# Real (production / TestFlight / Play Internal Testing)
flutter run --dart-define=PAYMENT_MODE=real
```

**Option B – flavor / env:**

If you use flavors, pass `PAYMENT_MODE` in your flavor’s dart-define or env so that release builds use `real` and dev/staging can use `mock`.

**Rule:** Remove or disable mock mode in release builds (e.g. force `PAYMENT_MODE=real` for release).

---

## 2. Release build requirement (review hardening)
- In **release** builds, `PAYMENT_MODE` must be **real**. If it is not, the app shows a blocking screen and disables purchase/restore (`MOCK_DISABLED_IN_RELEASE`).
- Build release with: `flutter build apk --dart-define=PAYMENT_MODE=real` and `flutter build ios --dart-define=PAYMENT_MODE=real`.
- Mock UI (e.g. "وضع تجريبي") is only shown when not in release (`!kReleaseMode`).

## 3. Product IDs

- **iOS:** `lifetime_all_access` (Non-Consumable in App Store Connect).
- **Android:** `lifetime_all_access` (One-time product in Play Console).

---

## 4. Flutter implementation summary

| File | Purpose |
|------|--------|
| `lib/services/iap_service.dart` | InAppPurchase init, buy/restore, mock vs real, calls Edge Function `verify_lifetime_purchase`. |
| `lib/providers/entitlement_provider.dart` | State: loading, hasLifetimeAccess, error. Methods: loadEntitlementFromServer(), buyLifetime(), restorePurchases(). |
| `lib/screens/paywall_screen.dart` | UI: price, Buy, Restore, “Lifetime Access Active” when entitled, loading & errors. |
| `lib/utils/ios_receipt.dart` | iOS: read app receipt (native), refresh if missing, base64 for verify. |
| Subscription screen | On iOS, code/gateway CTA hidden. |
| Subscription repo | `hasActiveSubscription()` also checks `entitlements.lifetime_access`. |

**On app start / login:**  
- Entitlement is loaded when the user opens the paywall (and subscription status is loaded when the subscription screen or `hasActiveSubscriptionProvider` is used).

---

## 5. Android package name (for verification)
- Set `ANDROID_PACKAGE_NAME` when building for Android so the backend can validate the request:  
  `--dart-define=ANDROID_PACKAGE_NAME=com.meda.app`  
- This value must match the Edge Function secret `ANDROID_PACKAGE_NAME`.

## 6. Supabase database

**Migration:** `supabase/migrations/033_entitlements.sql`

**Table:** `entitlements`

- `user_id` (uuid, PK, references auth.users)
- `lifetime_access` (boolean, default false)
- `platform` (text: 'ios' | 'android')
- `product_id` (text)
- `ios_original_transaction_id` (text, unique)
- `ios_latest_transaction_id` (text)
- `android_purchase_token` (text, unique)
- `updated_at` (timestamptz)

**RLS:**  
- Users can **SELECT** their own row.  
- **INSERT/UPDATE** only via service role (Edge Function).

Apply migration:

```bash
supabase db push
# or
supabase migration up
```

---

## 7. Edge Function: `verify_lifetime_purchase`

**Invoked by:** Flutter IAP service after a purchase or restore (or mock purchase).

**Input (JSON):**

```json
{
  "platform": "ios" | "android",
  "product_id": "lifetime_all_access",
  "receipt_data_base64": "<required for iOS>",
  "purchase_token": "<required for Android>",
  "mock": true | false
}
```

**Behavior:**

- Validates JWT (user must be authenticated).
- **If `mock === true`:**  
  - Allows only the user whose email equals **ADMIN_EMAIL**.  
  - Grants `lifetime_access = true` (upsert into `entitlements`).
- **If `mock === false`:**  
  - **iOS:** Verifies receipt with Apple (production, then sandbox if 21007). Checks product in receipt, extracts `original_transaction_id` and `transaction_id`, then upserts `entitlements`.  
  - **Android:** Verifies purchase with Google Play Developer API using `purchase_token` and `productId`, then upserts `entitlements`.
- **Response:**  
  `{ "ok": boolean, "lifetime_access": boolean }`

**Required secrets (Supabase Edge Function env):**

| Secret | Purpose |
|--------|--------|
| `SUPABASE_URL` | Set automatically by Supabase. |
| `SUPABASE_SERVICE_ROLE_KEY` | Set automatically. |
| `ADMIN_EMAIL` | Email allowed to get lifetime in **mock** mode. |
| `APPLE_SHARED_SECRET` | Optional; from App Store Connect → App → In-App Purchase → App-Specific Shared Secret. Recommended for production. |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Full JSON key for a service account with **Android Publisher** API access (for real Android verification). |
| `ANDROID_PACKAGE_NAME` | Application ID (e.g. `com.meda.app`) for Google Play API. |

Set secrets:

```bash
supabase secrets set ADMIN_EMAIL=your-admin@example.com
supabase secrets set APPLE_SHARED_SECRET=your_shared_secret
supabase secrets set ANDROID_PACKAGE_NAME=com.meda.app
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account.json)"
```

---

## 8. Testing

### Mock mode (no Apple/Google accounts needed)

1. Set `PAYMENT_MODE=mock` and run the app.
2. Set `ADMIN_EMAIL` in Supabase Edge Function secrets to the email you use to sign in.
3. Log in with that email, open Subscription → “شراء مدى الحياة عبر التطبيق” (or go to `/paywall`).
4. Tap “شراء الآن”. The app will call the Edge Function with `mock: true`; the backend will grant lifetime only for `ADMIN_EMAIL`.
5. You should see “Lifetime Access Active ✅” and `hasActiveSubscription` should be true (subscription screen and any gated content).

### Real mode – iOS (Sandbox)

1. Enroll in Apple Developer Program and create the app in App Store Connect.
2. In App Store Connect → Your App → In-App Purchase → create a **Non-Consumable** product with ID `lifetime_all_access`.
3. Create a **Sandbox** tester in Users and Access → Sandbox Testers.
4. On device/simulator (with Sandbox account in Settings → App Store), set `PAYMENT_MODE=real`, run the app, and complete a purchase.
5. Restore: tap “استعادة المشتريات” and confirm entitlement updates.

### Real mode – Android (License testers)

1. Create a Google Play Developer account and the app in Play Console.
2. In Play Console → Monetization → In-app products → create a **One-time product** with ID `lifetime_all_access`.
3. Add license testers (Setup → License testing).
4. Set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` and `ANDROID_PACKAGE_NAME` in Edge Function secrets.
5. Build with `PAYMENT_MODE=real`, install via internal testing, and purchase with a license tester account.
6. Test restore and reinstall; entitlement should persist after server verification.

---

## 9. Post-payment checklist (real mode)

- [ ] **Apple:** Enrolled in Apple Developer Program; Non-Consumable `lifetime_all_access` in App Store Connect; Sandbox tester created; tested buy + restore.
- [ ] **Google:** Google Play Developer account; One-time product `lifetime_all_access` in Play Console; license testers added; service account with Android Publisher API; tested buy + restore.
- [ ] **App:** `PAYMENT_MODE=real` for release builds; no external payment links inside the app.
- [ ] **Backend:** `verify_lifetime_purchase` deployed; all required secrets set; RLS and `entitlements` migration applied.
- [ ] **Content:** Gating uses server-backed entitlement only (e.g. `hasActiveSubscriptionProvider` / `entitlements.lifetime_access`), never client-only flags.

---

## 10. Rules (reminder)

- **Never** unlock content without server verification (Edge Function + `entitlements`).
- **Mock mode** must be disabled or unavailable in release builds.
- **No** external payment links inside the app for this lifetime product; use only IAP and the in-app paywall.
