# Books Feature — Database & Storage Setup

This document describes how to set up the **Books** feature in Supabase: table, indexes, RLS, storage buckets, security hardening, and admin access.

---

## 1. Run the migrations

Apply migrations in order so the `public.books` table, storage buckets, and security policies exist.

**Option A – Supabase CLI (recommended):**

```bash
cd /path/to/mada_app
supabase db push
```

**Option B – Manual SQL:**

1. Open the [Supabase Dashboard](https://app.supabase.com) → SQL Editor.
2. Run `supabase/migrations/035_books_table_and_storage.sql` first.
3. Then run `supabase/migrations/036_books_security_hardening.sql`.

---

## 2. Table: `public.books`

| Column           | Type         | Description                                          |
|------------------|-------------|------------------------------------------------------|
| id               | uuid        | PK, default `gen_random_uuid()`                      |
| title            | text        | Required, non-empty (trim length > 0)                |
| description      | text        | Optional                                              |
| author           | text        | Optional                                              |
| category         | text        | Optional                                              |
| language         | text        | Optional                                              |
| pages            | int         | Optional; if set, must be > 0                        |
| cover_url        | text        | Legacy/derived; use cover_path + signed URL           |
| cover_path       | text        | Storage path in bucket `book-covers` (e.g. covers/x.jpg) |
| file_url         | text        | Legacy/derived; use file_path + signed URL           |
| file_path        | text        | Storage path in bucket `book-files` (e.g. files/x.pdf); source of truth |
| file_type        | text        | `'pdf'` or `'epub'` (check)                          |
| file_size_bytes  | bigint      | Optional                                              |
| is_published     | boolean     | Default `false`                                      |
| is_featured      | boolean     | Default `false`                                     |
| sort_order       | int         | Default `0`, must be >= 0                            |
| created_by       | uuid        | References `auth.users(id)`                          |
| created_at       | timestamptz | Default `now()`                                     |
| updated_at       | timestamptz | Default `now()`, updated by trigger                  |

Indexes: `(is_published, sort_order)`, `(category)`, and trigram indexes on `title` and `author` (requires `pg_trgm` extension).

Migration **036** adds `cover_path`, `file_path`, backfills them from existing URLs where possible, and adds constraints: `pages` null or > 0, `sort_order` >= 0, non-empty `title`, and non-empty `file_path` when not null.

---

## 3. Storage buckets (private + signed URLs)

After **036**, both buckets are **private**:

| Bucket        | Purpose              | Allowed uploads (enforced by RLS) |
|---------------|----------------------|------------------------------------|
| **book-covers** | Cover images         | jpg, jpeg, png, webp               |
| **book-files**  | PDF/EPUB documents   | pdf, epub                          |

- **Access:** There are no public URLs. The app and admin use **signed URLs** (time-limited) from Supabase Storage `createSignedUrl(path, expirySeconds)`.
- **RLS – SELECT:**  
  - **Admins:** Can read any object in both buckets.  
  - **Other users:** Can read only objects whose path is stored in a **published** book (`books.is_published = true` and `books.cover_path` / `books.file_path` = object path).
- **RLS – INSERT/UPDATE/DELETE:** Admins only (via `public.is_admin(auth.uid())`).

So unpublished book files and covers cannot be accessed by non-admins, even with a direct URL.

---

## 4. Admin check: `public.is_admin(uid)`

Migration **036** adds a **SECURITY DEFINER** function:

- `public.is_admin(uid uuid) returns boolean`
- It returns true when `profiles.role` (trimmed, lowercased) contains `'admin'`.
- Used by all books and storage RLS policies so the role check is consistent and does not expose `profiles` in policy expressions.

---

## 5. Adding the first admin

Books management and storage write access are restricted to admins. To grant a user admin access:

1. Ensure the user has signed up so a row exists in `auth.users` and in `public.profiles`.
2. Set their role in `public.profiles` to include `'admin'`:

   ```sql
   update public.profiles
   set role = 'admin'
   where id = '<user_uuid>';
   ```

   Or by email:

   ```sql
   update public.profiles
   set role = 'admin'
   where id = (select id from auth.users where email = 'admin@example.com');
   ```

After this, that user can access the admin dashboard Books section and perform create/edit/delete and uploads.

---

## 6. Troubleshooting “Access denied”

- **User cannot see any books in the app**  
  - Only rows with `is_published = true` are visible to non-admins.  
  - Check that the book has `is_published = true` and that RLS policies for `public.books` are in place (migrations 035 + 036).

- **User cannot open a book file or see a cover (signed URL fails)**  
  - Buckets are private; access is only via signed URLs.  
  - Storage RLS allows read only for objects referenced by a **published** book (`cover_path` / `file_path` matching the object path).  
  - Confirm the book is published and that `cover_path` / `file_path` are set and match the object paths in storage.

- **Admin cannot upload or manage books**  
  - Confirm the user’s `profiles.role` contains `'admin'` (e.g. `'admin'` or `'super_admin'`).  
  - Confirm migration **036** has been applied (so `public.is_admin()` and the new storage policies exist).  
  - Check Storage policies: only admins can INSERT/UPDATE/DELETE in `book-covers` and `book-files`.

- **“Failed to create signed URL” or 403 on storage**  
  - For **app (non-admin):** The book must be published and the object path must match `books.file_path` or `books.cover_path`.  
  - For **admin:** Ensure the user is recognized as admin (`is_admin(auth.uid())` = true).  
  - Ensure buckets exist and are named exactly `book-covers` and `book-files`.

---

## 7. Summary checklist

- [ ] Run migration `035_books_table_and_storage.sql` (or `supabase db push`).
- [ ] Run migration `036_books_security_hardening.sql`.
- [ ] Confirm `public.books` has `cover_path` and `file_path` and RLS is enabled.
- [ ] Confirm buckets `book-covers` and `book-files` exist and are **private**.
- [ ] Confirm storage RLS: admins can read/write all; others can read only objects for published books.
- [ ] Set at least one user’s `profiles.role` to `'admin'` for Books management.

---

## 8. Verification (test checklist)

Use this to verify security and correctness after deployment:

1. **Non-admin cannot access unpublished book row**  
   As a non-admin (or anon), query `books` with `is_published = false` — no rows should be returned.

2. **Non-admin cannot access unpublished book file/cover by URL**  
   For a book with `is_published = false`, try to open the file or cover URL (e.g. via signed URL or any direct link). Access should be denied (403 or equivalent).

3. **Non-admin can access published book row and open file**  
   As a non-admin, list books (only published) and open a published book’s file using the app (signed URL). It should succeed.

4. **Admin can create/edit/delete books and upload assets**  
   As an admin, create a book with cover and file upload, edit it, toggle published/featured, then delete (storage objects and row should be removed).

5. **Storage update cannot move object to another bucket**  
   Storage UPDATE policies use `WITH CHECK (bucket_id = '...')`, so the bucket cannot be changed on update.
