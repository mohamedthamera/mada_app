# Mada App – Product Requirements Document (PRD)

This document describes the Mada application for TestSprite test generation. The app is a Flutter-based learning platform (RTL Arabic) with courses, books, jobs, and subscription gating.

## Product Overview

**Mada** is a mobile-first learning and career platform. Users can browse featured courses, read books, and view job listings. Access to courses (non-free lessons), books, and jobs requires an active subscription. The app supports login/signup, subscription management (including voucher redemption), and profile/referral flows.

## Core Goals

- Provide a seamless Arabic (RTL) learning experience across courses, books, and jobs.
- Gate premium content (courses, books, jobs) behind an active subscription.
- Allow users to manage profile, redeem subscription codes, and use referral codes.
- Support responsive layouts (mobile and web via Flutter).

## Key Features

### 1. Authentication
- **Splash** (`/splash`) – Initial loading.
- **Onboarding** (`/onboarding`) – First-time onboarding.
- **Login** (`/login`) – Email/password login.
- **Signup** (`/signup`) – User registration.
- **Set new password** (`/set-new-password`) – Password reset flow.
- Unauthenticated users are redirected to `/login` except for public paths: `/splash`, `/onboarding`, `/login`, `/signup`.

### 2. Home & Navigation
- **Home** (`/home`) – Dashboard with featured courses and entry points.
- **Bottom navigation**: Home, Courses, Books, Progress, Jobs, Profile.
- Shell route: `/home`, `/courses`, `/books`, `/progress`, `/jobs`, `/profile`.

### 3. Courses
- **Course list** (`/courses`) – List of courses with categories/levels.
- **Course details** (`/courses/:id`) – Course info and lessons.
- **Lesson player** (`/lesson/:id?courseId=`) – Video/content player; non-free lessons show a “locked” message and CTA to subscription.
- **Quiz** (`/quiz`) – Quizzes related to courses.
- **Certificates** (`/certificates`) – User certificates.

### 4. Books
- **Books list** (`/books`) – Gated by subscription; without subscription shows locked view with “الذهاب للاشتراك”.
- **Book details** (`/books/:id`) – Gated by subscription; shows book info and open/download PDF or file.

### 5. Jobs
- **Jobs list** (`/jobs`) – Gated by subscription; without subscription shows locked view. With subscription: search, filters (job type), and job cards opening a detail bottom sheet.

### 6. Subscription
- **Subscription** (`/subscription`) – Subscription status and voucher code redemption (`redeem_lifetime_code`).
- Critical for accessing books, jobs, and non-free course lessons.

### 7. Progress & Profile
- **Progress** (`/progress`) – User progress (courses, books).
- **Profile** (`/profile`) – User info, settings, and links (e.g. referral, notifications, community, contact, about).
- **Referral** (`/referral`) – Referral code usage.
- **Notifications** (`/notifications`), **Community** (`/community`) – Supporting screens.

## User Flows (Summary)

1. **Anonymous**: Open app → Splash → Onboarding (if first time) → Login/Signup.
2. **Authenticated**: Login → Home → Navigate to Courses / Books / Jobs / Progress / Profile.
3. **Subscription-gated**: From Books or Jobs without subscription → See locked view → “الذهاب للاشتراك” → Subscription page.
4. **Course learning**: Courses → Course details → Lesson (free or locked) → Quiz / Certificate.
5. **Subscription**: Subscription screen → Enter voucher code → Redeem → Access gated content.

## Validation Criteria (Testing Focus)

- **Auth**: Login and signup succeed with valid credentials; redirect to `/home` when logged in; unauthenticated redirect to `/login` for protected routes.
- **Navigation**: All main tabs (Home, Courses, Books, Progress, Jobs, Profile) are reachable and show expected content or locked view where applicable.
- **Subscription gating**: Books list and Book details show locked view when user has no active subscription; Jobs list shows locked view when user has no active subscription.
- **Subscription flow**: Subscription page loads; voucher redemption can be tested with a valid test code (if provided).
- **Courses**: Course list loads; course details open; lesson player shows content for free lessons and locked state for paid lessons with CTA to subscription.
- **RTL / Arabic**: UI is RTL; key labels and buttons are in Arabic (e.g. “الذهاب للاشتراك”, “دورات مميزة”, “الكتب”, “الوظائف”).
- **Error handling**: Network/API errors show user-friendly messages or retry options where implemented.

## Technical Context

- **Stack**: Flutter (Dart), GoRouter, Riverpod, Supabase (auth + backend).
- **Platforms**: Mobile (iOS/Android), Web (for TestSprite: run Flutter web and test in browser).
- **RTL**: Layout and text direction are RTL for Arabic.
- **Auth**: Supabase Auth; subscription status from backend (e.g. `hasActiveSubscription`).

## TestScope Recommendation

- **Frontend (UI)**: Test the **web** build (`flutter run -d chrome` or `flutter run -d web-server --web-port=8080`). Default web port is often **8080** (or as shown in terminal).
- **Bootstrap**: Use `type: "frontend"`, `testScope: "codebase"`, and `needLogin: true` with test credentials if auth is required for main flows.
- **Project path**: Use the **workspace root** (`/Users/mohammedthamer/Desktop/mada_app`) or the **mobile app** root (`.../mada_app/apps/mobile`) depending on whether TestSprite expects the whole repo or the app package. Prefer workspace root if tests reference both apps.
