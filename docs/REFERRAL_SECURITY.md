# Referral / Influencer Codes — Security & Edge Cases

## Overview

The referral system is **analytics-only**: it tracks which influencer (by code) brought which user. No payments or secrets are stored in the app.

---

## Security

### No referral overwrite

- **Database:** `user_referrals.user_id` is the primary key; a user can have at most one row.
- **RPC:** `apply_referral_code` checks for an existing referral before inserting. If one exists, it returns `"Referral already set"` and does not modify the row.
- **RLS:** Users can only `INSERT` into `user_referrals` with `user_id = auth.uid()`. There are no `UPDATE` or `DELETE` policies for normal users, so a referral cannot be changed or removed by the user after it is set.

### RLS (Row Level Security)

- **influencers**
  - **SELECT:** Only rows where `is_active = true` and `deleted_at is null` are visible to the public. This allows the app to validate codes and show names without exposing inactive/deleted influencers.
  - **INSERT/UPDATE/DELETE:** No policies for `authenticated` or `anon`; only the service role (used by the Edge Function) can modify influencers.

- **user_referrals**
  - **INSERT:** Allowed only when `user_id = auth.uid()` (user can only create their own referral).
  - **SELECT:** Allowed only when `user_id = auth.uid()` (user sees only their own row).
  - **UPDATE/DELETE:** No policies; referral is immutable for the user.

### RPC: `apply_referral_code`

- **SECURITY DEFINER** with `search_path = public` so the function runs with definer rights and a safe schema.
- Requires `auth.uid()`; returns an error if not authenticated.
- Validates that the code exists, is active, and not soft-deleted before inserting.
- Code comparison is case-insensitive (trim + upper) for a consistent UX.

### Admin: Edge Function `manage_influencer_codes`

- **Authentication:** Requires a valid JWT (Bearer token).
- **Authorization:** Admin is determined by:
  - `profiles.role` containing `"admin"`, or
  - User email in `ADMIN_EMAILS` env var (comma-separated, case-insensitive).
- Non-admin requests receive **403 Forbidden**.
- All DB writes use the **service role** client so RLS does not block admin operations.

### No secrets in Flutter

- No API keys or admin credentials are stored in the mobile or admin app.
- Admin actions go through the Edge Function with the user’s JWT; the function checks admin status server-side.

---

## Edge Cases

1. **User already has a referral**
   - RPC returns `ok: false`, `error: "Referral already set"`. The UI should hide the input and show the existing code.

2. **Invalid or inactive code**
   - RPC returns `ok: false`, `error: "Invalid or inactive code"`. Show a clear message; do not create a referral.

3. **Signup with referral code and email confirmation**
   - If your auth flow requires email confirmation, the user may not be logged in immediately after signup. Applying the referral code right after signup can fail with "not authenticated". The app handles this by:
     - Trying to apply the code after signup when the user is already logged in (e.g. no confirmation).
     - If it fails, showing a message and letting the user enter the code later from the "كود الإحالة" screen once they are logged in.

4. **Admin disables a code**
   - Setting `is_active = false` (or soft delete) prevents new users from using the code. Existing `user_referrals` rows are unchanged; analytics remain correct.

5. **Soft delete (deleted_at)**
   - Influencers are only soft-deleted. The view `influencer_stats` excludes them (`deleted_at is null`). Referral counts and history stay intact.

6. **Scalability**
   - `user_referrals` is keyed by `user_id` and `influencer_id`. Index on `influencer_id` supports counting users per influencer (e.g. 10K+ per influencer). The stats view uses a left join and count; for very large data, consider a materialized view refreshed periodically.

---

## Analytics & Reporting

- **Total users per influencer:** Use the `influencer_stats` view (`influencer_id`, `influencer_name`, `referral_code`, `total_users`, `is_active`).
- **Sort by performance:** Order by `total_users DESC`.
- **CSV export:** Query `influencer_stats` (or the underlying tables with a join) and export columns as needed.
- **Charts:** Use `influencer_stats` as the source for bar/line charts (e.g. users per influencer over time would require joining `user_referrals.referred_at` with a time bucket).
