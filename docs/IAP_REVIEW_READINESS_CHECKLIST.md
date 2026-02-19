# Lifetime IAP — App Store & Play Store Review Readiness Checklist

Use this checklist before submitting your app for Apple App Review and Google Play Review.

---

## Apple App Store

### Restore Purchases
- [ ] **Restore Purchases** button is visible and easy to find on the paywall (e.g. below “Buy”).
- [ ] Tapping **Restore** restores previous non-consumable purchase and updates entitlement after server verification.
- [ ] After restore, the user sees “Lifetime Access Active” (or equivalent) and can access all content.
- [ ] Test with a Sandbox account: purchase → delete app → reinstall → Restore → confirm access.

### Server Verification
- [ ] Entitlement is **always** determined by your backend (Supabase `entitlements` table), not only by client-side purchase state.
- [ ] iOS receipt is read from **appStoreReceiptURL** (or equivalent), base64-encoded, and sent to `verify_lifetime_purchase`.
- [ ] If receipt is missing, a receipt refresh is triggered before verification.
- [ ] Content is never unlocked based solely on a local purchase flag without server verification in real mode.

### Mock Mode & Release Builds
- [ ] **PAYMENT_MODE** is set to **real** in release builds (e.g. `--dart-define=PAYMENT_MODE=real`).
- [ ] In release, if PAYMENT_MODE is not `real`, the app shows a blocking message and does **not** allow purchase or restore (no mock flow).
- [ ] No “mock” or “test purchase” UI is visible in release builds.
- [ ] Build and run a release/profile build and confirm buy/restore use the real store only.

### No External Payment for Digital Content (iOS)
- [ ] On **iOS**, the subscription/paywall screen does **not** show CTAs for “code redemption” or “external gateway” that unlock the same in-app digital content (courses, etc.).
- [ ] Unlocking in-app digital content on iOS is only via **In-App Purchase** (and optionally Restore).
- [ ] Code/gateway flow (if any) is hidden on iOS or used only for non-digital unlocks (e.g. physical goods).

### Paywall Copy & Legal
- [ ] Paywall clearly states **“Lifetime access (one-time purchase)”** or equivalent (e.g. “شراء لمرة واحدة”).
- [ ] No misleading subscription language (e.g. “monthly” or “recurring”) for this product.
- [ ] **Terms of Use** and **Privacy Policy** links are present on or near the paywall (e.g. footer).
- [ ] User can open Terms and Privacy from the paywall without leaving the purchase flow context.

### Error Handling
- [ ] Clear, user-friendly error messages (e.g. “No purchase found. Please complete a purchase first.” for missing receipt).
- [ ] Restore shows an appropriate message when there are no purchases to restore (e.g. “No purchases to restore” or success with no change).
- [ ] No raw stack traces or internal codes shown to the user.

---

## Google Play

### Restore / Reinstall
- [ ] **Restore** (or equivalent) is available and restores one-time product entitlement after server verification.
- [ ] Test: purchase → clear data or reinstall → open app → restore → confirm lifetime access from server.
- [ ] One-time product is **acknowledged** (or not consumed) as per Play Billing; entitlement is stored by your backend.

### Server Verification
- [ ] Backend verifies Android purchases with **Google Play Developer API** (`purchases.products.get` for one-time product).
- [ ] Validation includes: `purchaseState == PURCHASED`, `productId` match, `purchaseToken` valid, `packageName` matches your app.
- [ ] `android_purchase_token` is stored in `entitlements` and used to avoid duplicate grants.
- [ ] Content is never unlocked without successful server verification in real mode.

### Mock Mode & Release
- [ ] Same as Apple: PAYMENT_MODE=real in release; no mock purchase path or mock UI in production.

### Paywall & Legal
- [ ] Same as Apple: clear one-time purchase wording, Terms and Privacy links on paywall, Restore visible and working.

### Error Handling
- [ ] Clear errors for invalid token, canceled purchase, or server failure; no internal codes exposed to the user.

---

## Backend (Supabase)

### Secrets
- [ ] **ADMIN_EMAIL** — set for mock mode (dev only).
- [ ] **ANDROID_PACKAGE_NAME** — your app’s package name (e.g. `com.meda.app`).
- [ ] **GOOGLE_PLAY_SERVICE_ACCOUNT_JSON** — full JSON key for Play Developer API (Android).
- [ ] **APPLE_SHARED_SECRET** — App-Specific Shared Secret from App Store Connect (optional but recommended for iOS).
- [ ] **SUPABASE_URL** and **SUPABASE_SERVICE_ROLE_KEY** — set by Supabase; Edge Function uses them.

### Database & RLS
- [ ] Table **entitlements** has `created_at`, `updated_at` (with trigger), and unique constraints on `ios_original_transaction_id` and `android_purchase_token`.
- [ ] RLS: users can **SELECT** only their own row; **INSERT/UPDATE** only via service role (Edge Function).
- [ ] Migration `033_entitlements.sql` (or latest) applied.

### Edge Function
- [ ] **verify_lifetime_purchase** deployed and invoked with valid JWT.
- [ ] Responses include **ok**, **lifetime_access**, and on error **code** and **message** (e.g. RECEIPT_MISSING, APPLE_VERIFY_FAILED, GOOGLE_VERIFY_FAILED, NOT_PURCHASED, MOCK_DENIED).
- [ ] Logging does not expose secrets (no receipt data, tokens, or keys in logs).

---

## Final Checks

- [ ] **Release build** tested on a real device: buy and restore both work and update server entitlement.
- [ ] **No external payment** links or CTAs for unlocking the same digital content on iOS.
- [ ] **Terms of Use** and **Privacy Policy** are linked from the paywall and open correctly.
- [ ] **Mock mode** is disabled or unreachable in release (compile-time or runtime guard).

Once all items are checked, the app is in a strong position for App Store and Play Store review for the lifetime IAP feature.
