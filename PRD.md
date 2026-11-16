# PRD: Rafiq — Shared Worship Accountability for Muslims

> Working name: **Rafiq** (رفيق, "companion"). Alternatives: *Suhbah*, *Saff*, *Ummah Duo*, *Barakah Bond*.
> Platform: Android (Flutter). iOS planned for Phase 3.
> Version: 1.0 draft · Owner: Founder · Last updated: 15 Nov 2026

---

## 0. TL;DR

Rafiq is a habit tracker for worship that you share with other people. Spouses, friends, siblings, or a small circle join a **Bond** with an invite code. They log their five daily prayers, dhikr, and Quran reading, and see a combined "together" progress ring. They can also send each other gentle nudges before a prayer window closes.

Palko/Dot proved that couples will use **shared progress visuals** for health habits. Rafiq brings that model to worship, which Muslims do 5+ times a day, every day. The difference is that Rafiq is designed **against shame, comparison, and riya (showing off)**.

**North-star metric:** Weekly Active Bonds (a bond counts if at least 2 members logged on 4 or more days that week).

---

## 1. Problem

1. **Consistency is hard alone.** Many Muslims want to pray all five prayers on time, keep up morning and evening adhkar, and read Quran daily, but they slip. Solo trackers (Muslim Pro, Pillars, and others) give reminders and nothing more. There is no person on the other end.
2. **Accountability already exists in the faith, but not in apps.** Islam encourages righteous companionship (*suhbah*) and mutual encouragement toward good. In real life this happens with spouses, roommates, and halaqa friends, but it's informal and gets forgotten.
3. **Spouses are often uneven.** One spouse is consistent and the other struggles. Asking "did you pray?" in person can feel like nagging or judgment. Couples need a soft channel for encouragement.
4. **Existing social habit apps are built on competition.** Leaderboards and comparison breed ego and riya, which go against the spirit of worship. Religious users feel uncomfortable with that.

## 2. Vision & Positioning

> "Your companion on the path. Pray together, even when apart."

- **Not** a prayer-times app. Prayer times are a supporting feature.
- **Not** a social network. There is no public feed, no followers, and no likes.
- **It is** a private, small-group space for encouragement where progress is shared and **framed collectively**.

**Positioning statement:** For Muslims who want to be more consistent in worship, Rafiq is a shared tracker that pairs you with the people you love so you can encourage each other gently. Unlike solo prayer apps, Rafiq turns worship into a shared journey without turning it into a competition.

## 3. Design Principles (non-negotiable)

| # | Principle | What it means in practice |
|---|---|---|
| P1 | **Together > versus** | The main metric is combined %. Individual numbers are secondary and can be hidden. No leaderboards in MVP. |
| P2 | **No shame** | Missed prayers show as neutral grey, never red. Copy never says "you failed." Making up a missed prayer (qada) counts as a positive action. |
| P3 | **Privacy by default** | Members choose what they share: *Done/Not done*, *On time/late*, or *Nothing (private)*. Per habit. |
| P4 | **Sincerity (ikhlas) first** | No public sharing of worship stats by default. Share cards say "we" and never show individual counts. Gentle reminders say the deed is between you and Allah. |
| P5 | **One tap** | Logging a prayer must take at most 1 tap from the notification or widget. |
| P6 | **Offline first** | Prayer times and logging work with no internet and sync later. Many users in South Asia and Africa have spotty data. |
| P7 | **Respect the scholars** | Calculation methods and madhab-specific Asr are configurable. Religious content is sourced and cited. |

## 4. Target Users & Personas

### Primary markets (launch)
- **Bangladesh, Pakistan, India, Indonesia, Malaysia, Egypt, Nigeria, Turkey**: large Muslim populations, mostly Android.
- **Diaspora (UK, US, Canada, Gulf)**: higher willingness to pay. Mostly iOS, which is why iOS comes in Phase 3.

### Personas

**1. Ayesha & Rafi: newly married couple (core persona)**
- 26 and 28 years old, Dhaka. Ayesha prays all five. Rafi often misses Fajr and Asr at work.
- Ayesha wants to encourage him without nagging. Rafi wants to improve without feeling watched.
- Needs: soft nudges, a shared streak, and privacy over timing details.

**2. Hamza's halaqa circle: friends' group**
- Five university friends in Lahore who made a pact for Ramadan.
- Needs: a group circle, shared Quran khatm (splitting juz), and group dhikr goals.

**3. Sara: revert / new Muslim**
- 31 years old, London. Learning to pray, and her mentor from the mosque supports her.
- Needs: gentle beginner mode (start with 1–2 prayers), a mentor bond, and learning content.

**4. Umm Yusuf: parent**
- She wants her 12-year-old to build the prayer habit.
- Needs: family bond, kid-friendly rewards, parental view. *(Phase 2, with child-safety review.)*

## 5. Competitive Landscape (to verify before launch)

| Category | Examples | Gap Rafiq fills |
|---|---|---|
| Prayer times / all-in-one | Muslim Pro, Athan, Pillars | Solo only, no partner accountability |
| Prayer trackers | Various "Salah tracker" apps | Solo, often shame-y (red X's) |
| Quran apps | Tarteel, Quran.com | Reading, not shared habit |
| Couples habit apps | Palko/Dot, Paired, Couples-style trackers | Not religious and no prayer-time awareness |
| Generic group habits | Habitica, Streaks-with-friends | Competitive and gamified, which conflicts with ikhlas |

> **Action item:** Do a Play Store teardown of the top 10 "salah tracker" and "muslim habit" apps. Look at installs, ratings, and 1-star complaints, and find any competitor with a partner feature.

## 6. Scope Overview

| Phase | Timeline (target) | Theme |
|---|---|---|
| **MVP (v1.0)** | Dec 2026 – Jan 2027 | Bonds + 5 prayers + nudges + dhikr + together ring |
| **v1.1 Ramadan** | Released by ~5 Feb 2027 (Ramadan expected around mid-Feb 2027, confirm date) | Fasting, Taraweeh, Quran khatm, iftar countdown |
| **v1.5** | Apr – Jun 2027 | Widgets 2.0, insights, custom habits, du'a requests |
| **v2.0** | H2 2027 | iOS launch, family mode, premium tier, Wear OS |

---

## 7. MVP Functional Requirements (v1.0)

Priority: **P0** = must ship, **P1** = should ship, **P2** = nice to have.

### 7.1 Onboarding & Auth

| ID | Requirement | Priority |
|---|---|---|
| ON-1 | Sign in with Google (main path on Android) and email OTP as a fallback. No passwords. | P0 |
| ON-2 | Ask for display name and optional avatar (emoji/color picker, **no photos** in MVP for privacy). | P0 |
| ON-3 | Location for prayer times: request permission, with manual city search as a fallback. Store coarse location only. | P0 |
| ON-4 | Pick a calculation method (auto-suggest by country, e.g. Karachi for BD/PK, MWL, Egyptian, Umm al-Qura, ISNA) and Asr juristic method (Shafi'i/Hanafi). | P0 |
| ON-5 | "What do you want to grow in?" multi-select: 5 prayers (default on), morning/evening adhkar, dhikr counter, Quran pages. | P0 |
| ON-6 | Beginner mode: "Start with fewer prayers and build up," where the user selects 1–5 prayers to track. | P1 |
| ON-7 | Notification permission prompt (Android 13+ POST_NOTIFICATIONS) with an explanation screen first. | P0 |
| ON-8 | End onboarding with **"Invite your companion"** (create bond) or "I have a code" (join). It can be skipped, and solo mode works. | P0 |
| ON-9 | Language: English and Bangla at launch. Arabic, Urdu, and Indonesian in v1.5. Architect for RTL from day 1. | P0 (EN/BN) |

**Acceptance:** A new user goes from install to logging their first prayer in under 90 seconds, measured by funnel analytics.

### 7.2 Bonds (the core)

A **Bond** is a private group of 2–8 people.

| ID | Requirement | Priority |
|---|---|---|
| BD-1 | Create a bond: choose a type (**Duo**, 2 people, or **Circle**, 3–8), a name (default "Ayesha & Rafi"), and a color pair/theme. | P0 |
| BD-2 | Generate a 6-character invite code (unambiguous charset, no 0/O/1/I) and a deep link `rafiq.app/j/ABC123`. Code expires in 7 days and can be regenerated. | P0 |
| BD-3 | Share the invite through the Android share sheet, with a rich WhatsApp/Messenger preview (OG image showing the bond name). | P0 |
| BD-4 | Join by code or link. A new user installs from the link, and the deferred deep link auto-joins after signup. | P0 (code), P1 (deferred) |
| BD-5 | A user can be in up to **3 bonds** in MVP (e.g., spouse + friends + sibling). Each habit's privacy is set per bond. | P0 |
| BD-6 | Leave bond at any time. If the bond creator leaves, admin passes to the longest-standing member. | P0 |
| BD-7 | Remove member (admin only, circles only). Duos can only be dissolved, not have a member removed. | P1 |
| BD-8 | Bond intention (niyyah) at creation: an optional short shared line like "To be among those who pray Fajr in jama'ah" shown at the top of the bond screen. | P1 |
| BD-9 | Report or block a member. Blocking removes them from shared bonds immediately. | P0 |

### 7.3 Prayer Tracking

| ID | Requirement | Priority |
|---|---|---|
| PR-1 | Calculate daily prayer times on-device (Dart `adhan` package). Show Fajr, Sunrise (info only), Dhuhr, Asr, Maghrib, Isha. Friday shows "Jumu'ah" instead of Dhuhr. | P0 |
| PR-2 | Log each prayer with one of these statuses: **On time**, **Late (still within window)**, **Qada (made up later)**, **Missed**, or unlogged. Default tap = "Prayed" and timing is auto-inferred by log time (editable). | P0 |
| PR-3 | Optional: "Prayed in jama'ah/masjid" toggle, which adds a small badge. | P1 |
| PR-4 | Edit or undo logs for today and yesterday only, to keep things honest without being strict. | P0 |
| PR-5 | Excused-days mode (for menstruation): a private toggle that **pauses** prayer tracking without breaking streaks. It is **never shown to bond members** except as a generic "paused" if the user chooses. Wording is careful and discreet. | P0 |
| PR-6 | Travel mode: an option to mark prayers as shortened/combined (qasr/jam'). | P2 |
| PR-7 | Adhan/reminder notification at prayer time with action buttons **"Prayed ✓"** and **"Remind me in 15m"**. | P0 |
| PR-8 | Optional pre-end reminder: "Asr ends in 30 min." User sets the offset. | P1 |
| PR-9 | Prayer-time adjustments (±minutes per prayer) for local mosque differences. | P1 |

**Prayer-window logic:** A prayer's window runs from its start to the next prayer's start. Fajr ends at sunrise. Isha ends at Fajr, or at midnight as a configurable option. "On time" means logged within the window. Users can override.

### 7.4 Dhikr & Adhkar

| ID | Requirement | Priority |
|---|---|---|
| DH-1 | Tasbih counter: full-screen tap area, haptic each tap, stronger haptic every 33/100. Volume-key counting option. | P0 |
| DH-2 | Preset dhikr: SubhanAllah, Alhamdulillah, Allahu Akbar, La ilaha illallah, Astaghfirullah, Salawat. Each shows Arabic, transliteration, and meaning. | P0 |
| DH-3 | Custom dhikr with a user-defined target. | P1 |
| DH-4 | **Shared dhikr goal** in a bond, e.g. "1,000 Salawat together this Friday." Everyone's taps add to one shared progress bar. | P0 |
| DH-5 | Morning/evening adhkar checklist (sourced from Hisn al-Muslim, with references). Each dhikr shows text, count, and source, plus a "done" check. | P1 |
| DH-6 | Counter state persists across app kills, so a session can be resumed. | P0 |

### 7.5 Quran (lite in MVP)

| ID | Requirement | Priority |
|---|---|---|
| QR-1 | Log pages or ayahs read today (simple stepper). No Quran reader in MVP. | P1 |
| QR-2 | Daily page goal. | P1 |
| QR-3 | Shared Khatm: split 30 juz among bond members, each member claims juz, and the bond tracks overall completion. | **v1.1 (Ramadan)** |

### 7.6 Together Dashboard (home screen)

This is the most important screen, inspired by Palko's arc but built for worship.

**Layout (top to bottom):**
1. **Header:** bond name, bond switcher (if more than 1 bond), shared streak 🔥, menu.
2. **Together Arc:** a semicircle of dots. Each member has a color, and each dot is one completed deed. The large number in the center is **"Together today: 78%."** Below it: "Yesterday 100%."
3. **Next prayer card:** "Asr in 42 min · 4:12 PM," with each member's status for the *previous* prayer shown as soft dots (respecting privacy).
4. **Today's prayers row:** 5 pills (F D A M I). Each pill shows small colored dots for the members who completed it.
5. **Habit cards grid:** Dhikr (shared goal progress bar), Adhkar (morning/evening checks), Quran (pages per member).
6. **Floating action button:** quick log (opens a sheet with the next unlogged prayer pre-selected).

**Rules:**
- Together % = (sum of completed tracked items across all members) / (sum of tracked items across all members). Excused/paused items are removed from both the numerator and the denominator.
- Individual breakdown is shown **only** for habits the member shares at the "Done/Not done" level or above.
- Missed items are **neutral grey**. Completed items use the member's color.
- **Celebration moment:** at 100% together, a soft animation plays (e.g., a crescent fills) with the copy "MashaAllah, you completed today together 🤍." No sound by default.

| ID | Requirement | Priority |
|---|---|---|
| DB-1 | Together Arc + % with real-time updates within 3 seconds of a partner's log. | P0 |
| DB-2 | Bond switcher. | P0 |
| DB-3 | Solo view tab (personal stats only, never shared). | P0 |
| DB-4 | Pull to refresh, with offline badge when stale. | P0 |

### 7.7 Nudges (core growth loop)

| ID | Requirement | Priority |
|---|---|---|
| NG-1 | **Send a nudge** to a member: choose from kind presets ("Asr is ending soon, let's pray 🤍", "Missed you at Fajr, let's catch Dhuhr together", "Proud of you!"). Free-text messages are **not** in MVP, for moderation reasons. | P0 |
| NG-2 | **Smart nudge prompt:** if a member hasn't logged a prayer and less than 30 min remain in its window, other members get "Rafi hasn't logged Asr yet. Send a gentle reminder?" Each member can turn this off. | P0 |
| NG-3 | Rate limits: max 1 nudge per sender per recipient per prayer. Max 5 nudges received per day across a bond. | P0 |
| NG-4 | Recipient controls: mute nudges from a bond, or set quiet hours. | P0 |
| NG-5 | **Du'a reaction:** after a member logs, others can tap 🤲 to send "May Allah accept it" (*Taqabbal Allah*). This is the lightweight social glue. | P0 |
| NG-6 | "Wake for Fajr" request: a member can ask a partner to call or nudge them at Fajr. The partner gets an alarm-style reminder. | P2 |

**Tone guardrails:** All preset copy will be reviewed by at least one person with Islamic studies background plus 5 beta users. No guilt language, no "you missed," no numbers in nudges.

### 7.8 Streaks

| ID | Requirement | Priority |
|---|---|---|
| ST-1 | **Shared streak:** consecutive days on which the bond's together % is at least the threshold (default 60%, adjustable by the admin to 40/60/80/100). | P0 |
| ST-2 | Personal streak (private, solo tab). | P1 |
| ST-3 | **Streak shield:** 1 free "mercy day" per week that preserves the shared streak automatically. It's framed as Allah's mercy and ease, not as a game mechanic. | P1 |
| ST-4 | Milestone celebrations at 7, 30, 40, 100, and 365 days, with a shareable card (bond name and days only, **no individual stats**). | P1 |

### 7.9 Insights (lite)

| ID | Requirement | Priority |
|---|---|---|
| IN-1 | Weekly summary every Friday after Jumu'ah: "This week together: 82%. Fajr improved by 3 days 🌅." Delivered as a push notification and an in-app card. | P1 |
| IN-2 | Per-prayer heatmap for the last 30 days (solo view only). | P1 |
| IN-3 | Bond insights show **collective** trends only. | P1 |

### 7.10 Widgets & Notifications

| ID | Requirement | Priority |
|---|---|---|
| WG-1 | Home-screen widget (2x2): next prayer plus a one-tap "Prayed" button for the current prayer. | P0 |
| WG-2 | Widget (4x2): Together Arc mini + partner status dots. | P1 |
| NT-1 | Notification channels (Android): Prayer times, Nudges, Bond activity, Weekly summary. Each channel can be toggled separately. | P0 |
| NT-2 | Exact alarms for prayer times (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM handling for Android 12+, with fallback). | P0 |
| NT-3 | Battery-optimization education screen for aggressive OEMs (Xiaomi, Oppo, Vivo, Samsung), which are common in target markets. | P0 |

### 7.11 Settings & Privacy

- Per-bond, per-habit sharing level: **Full** (status + timing), **Basic** (done/not done), or **Private**.
- Hide my exact log times (on by default).
- Excused mode toggle (discreet).
- Notification controls, quiet hours.
- Export my data (JSON) and delete account (hard delete within 30 days, GDPR-style).
- Theme: Light / Dark / System. Accent colors.

---

## 8. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Performance | Cold start under 2s on a mid-range device (e.g., Redmi Note 12). Logging a prayer feels instant (optimistic UI). |
| APK size | Under 25 MB (important for emerging markets). Use app bundles and split ABIs. |
| Offline | Prayer times, logging, and dhikr work fully offline. Sync queue with conflict resolution (last-write-wins per log, plus server timestamps). |
| Battery | No constant background location. Recompute times daily and on significant location change only. |
| Min SDK | Android 7.0 (API 24) or higher. Target the latest SDK. |
| Accessibility | TalkBack labels, minimum 48dp touch targets, dynamic font scaling, color-blind-safe member palettes (pair colors with shapes). |
| Localization | ARB-based i18n. RTL support. Hijri date display. |
| Security | Firestore security rules: a user can only read bonds they belong to. Rate-limited Cloud Functions. No PII in analytics. |
| Reliability | 99.5% crash-free users target (Crashlytics). |

---

## 9. Technical Architecture (Flutter)

### 9.1 Stack

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter (stable), Dart 3 | Android first. iOS-ready codebase. |
| State | Riverpod 2 (with code gen) | Testable and scales well. |
| Navigation | go_router | Deep links for invites. |
| Local DB | Drift (SQLite) or Isar | Offline source of truth + sync queue. |
| Backend | **Firebase**: Auth, Firestore, Cloud Functions, FCM, Remote Config, Crashlytics, Analytics | Fastest for a solo dev. Real-time listeners. Alternative: Supabase (Postgres + RLS). |
| Prayer times | `adhan` (Dart port) | On-device and offline. |
| Notifications | `flutter_local_notifications` + FCM | Local for prayer times, FCM for nudges. |
| Widgets | `home_widget` + native Kotlin/Glance | Glance for modern Android widgets. |
| Deep links | Android App Links + Firebase Hosting `/.well-known/assetlinks.json` | Firebase Dynamic Links is deprecated, so use custom App Links plus Play Install Referrer for deferred joins. |
| Haptics | `HapticFeedback` / `vibration` | Dhikr counter. |
| Animations | Rive or Lottie | Together Arc and celebrations. |

### 9.2 Data Model (Firestore)

```
users/{uid}
  displayName, avatarEmoji, color, locale, timezone,
  calcMethod, asrMethod, coarseLocation {lat, lng, city},
  trackedHabits: [fajr, dhuhr, asr, maghrib, isha, adhkar_am, adhkar_pm, quran],
  createdAt, lastActiveAt

bonds/{bondId}
  name, type: "duo"|"circle", memberIds: [uid], adminId,
  inviteCode, inviteExpiresAt, intention, themeColors,
  streak {current, best, lastCountedDate}, streakThreshold,
  createdAt

bonds/{bondId}/members/{uid}
  joinedAt, color, role, sharing { fajr: "full"|"basic"|"private", ... },
  nudgesMuted, smartNudgeEnabled

bonds/{bondId}/days/{yyyy-MM-dd}          // aggregated by Cloud Function
  togetherPct, perMember {uid: {done, total}}, completedAt100?

logs/{uid}/days/{yyyy-MM-dd}               // owner-only raw data
  prayers { fajr: {status, loggedAt, jamaah}, ... },
  dhikr { subhanallah: 120, ... }, quranPages, excused: bool

bonds/{bondId}/goals/{goalId}              // shared dhikr / khatm
  type, title, target, progress, contributions {uid: n}, startsAt, endsAt

bonds/{bondId}/events/{eventId}            // nudges, reactions (TTL 7 days)
  type: "nudge"|"dua_reaction", fromUid, toUid, presetId, prayer, createdAt

inviteCodes/{code} → { bondId, expiresAt }
```

**Privacy architecture:** Raw logs live under `logs/{uid}` and only the owner can read them. A Cloud Function `onLogWrite` projects a **sanitized** view into `bonds/{bondId}/days` according to each member's sharing settings. Excused status is projected as "item removed," never as "excused." Bond members therefore cannot read sensitive raw data even with a modified client.

### 9.3 Cloud Functions
- `onLogWrite`: recompute bond day aggregates and update streaks.
- `joinBond(code)`: validate the code, add the member, enforce limits (8 members, 3 bonds per user).
- `sendNudge(bondId, toUid, presetId, prayer)`: rate-limit, then FCM push.
- `smartNudgeScheduler` (every 10 min): find members with an unlogged prayer and under 30 min left in its window, using each member's local times, then prompt partners.
- `dailyRollover` (per timezone): finalize streaks and apply shields.
- `weeklySummary` (Friday): generate insights.

### 9.4 Flutter Project Structure
```
lib/
  core/        (theme, router, l10n, utils, prayer_time_service)
  data/        (drift db, firestore repos, sync queue)
  features/
    onboarding/
    bonds/       (create, join, manage)
    dashboard/   (together arc, cards)
    prayers/
    dhikr/
    quran/
    nudges/
    insights/
    settings/
  widgets/     (shared UI)
android/app/src/main/kotlin/... (Glance widgets, exact alarm receiver)
```

---

## 10. UX / Visual Direction

- **Mood:** calm, warm, spiritual. **Not** a neon fitness app. Palko's playful arc works, but soften it.
- **Palette:** cream/off-white backgrounds, deep teal or emerald primary, soft gold accents. Member colors come from a curated set of 8 calm, color-blind-safe pairs.
- **Typography:** a rounded geometric sans (e.g., Plus Jakarta Sans / Nunito) and an Arabic font (Amiri or Noto Naskh Arabic) for dhikr text.
- **Iconography:** crescent, lantern, and prayer-mat motifs, subtle geometric Islamic patterns in empty states. **No** depictions of people's faces or animals in illustrations.
- **Key screens to design (MVP):**
  1. Welcome / value prop (3 slides)
  2. Sign in
  3. Location & calc method
  4. Habit selection
  5. Create or Join bond
  6. Invite share screen
  7. Together dashboard
  8. Prayer log sheet
  9. Dhikr counter (full screen)
  10. Shared goal detail
  11. Nudge composer sheet
  12. Bond settings / privacy
  13. Solo stats
  14. Settings
  15. Milestone celebration + share card

---

## 11. Copy & Tone Guide

| Do | Don't |
|---|---|
| "Let's pray Asr together 🤍" | "You missed Asr!" |
| "Together today: 60%" | "Rafi: 2/5, Ayesha: 5/5" (as headline) |
| "Every step back to Allah counts" | "Streak broken 💀" |
| "Taqabbal Allah, may Allah accept it" | "Nice job! +10 XP" |
| "Paused" | "Excused (period)" |

**Islamic content rules:** Every hadith or ayah shown must cite its source (e.g., *Sahih Muslim 656*). Avoid weak narrations. Have an advisor review the content.

---

## 12. Monetization

**Principle: core worship features are free forever.** Charging for prayer tracking would hurt trust.

| Free | Rafiq Plus (v2.0) |
|---|---|
| 5 prayers, dhikr, Quran log | Circles up to 15 members |
| Up to 3 bonds, 8 members | Unlimited bonds |
| Together dashboard, nudges | Advanced insights (monthly/yearly, trends) |
| Basic widget | Premium themes, widget styles, app icons |
| Shared streak + 1 shield/week | Extra shields, custom nudge packs |
| | Family mode extras |

- **Pricing (localized):** ~BDT 99/month or BDT 799/year; ~$2.99/month or $19.99/year in the West. Use Google Play Billing purchasing-power tiers.
- **Alternative / complementary:** "Support Rafiq" pay-what-you-want, and a Ramadan "sponsor a free year for a student" (sadaqah) model. This performs well with the audience and builds goodwill.
- **No ads.** Ads in a worship app damage trust, and ad networks may show haram content.

---

## 13. Go-To-Market & Growth

### 13.1 Built-in viral loop
`Install → create bond → invite partner (required for core value) → partner installs → both nudge → retention → milestone share card → new people see it → install`

- Target **K-factor ≥ 0.6** from invites alone.
- Invite share screen with a pre-written WhatsApp message in the user's language.

### 13.2 Launch plan
1. **Now – Dec 2026:** Waitlist landing page (like trypalko.com) with an interactive demo arc ("Log a prayer, watch your together ring grow"). Goal: 2,000 signups.
2. **Build in public** on TikTok, Reels, and X: "Building a prayer app for couples, Day 1…" This is the format in the videos you shared, and it works.
3. **Closed beta (Jan 2027):** 100 bonds (200+ users), recruited from university Muslim student associations, local masjid youth groups, and friends.
4. **Public Play Store launch: ~2–3 weeks before Ramadan 2027.**
5. **Ramadan campaign:** "30 days, together" challenge, a shared khatm, and creator partnerships (Muslim couples, Islamic reminder pages in BD/PK/ID/MY).
6. **Post-Ramadan retention:** "Keep the Ramadan glow" Shawwal 6-fasts challenge, then the Dhul Hijjah first-10-days challenge.

### 13.3 Channels
- Muslim content creators (couples, reverts, students). Many will promote faith apps for free or low cost if the app is ethical.
- MSAs, ISOCs, halaqas → "Circle" pitch.
- Masjid posters with a QR code during Ramadan.
- Play Store ASO keywords: *namaz tracker, salah tracker, prayer tracker with friends, couple prayer app, dhikr counter, tasbih, islamic habit tracker, নামাজ ট্র্যাকার*.

---

## 14. Analytics & Success Metrics

### Events (Firebase Analytics, no PII)
`onboarding_step_completed`, `bond_created`, `invite_shared(channel)`, `bond_joined(via: code|link)`, `prayer_logged(prayer, status, source: app|notif|widget)`, `dhikr_session(count)`, `nudge_sent(preset)`, `nudge_opened`, `dua_reaction_sent`, `streak_milestone(days)`, `together_100_day`, `widget_added`.

### Targets (first 90 days after launch)

| Metric | Target |
|---|---|
| Install → first prayer logged | ≥ 70% |
| Install → in a bond with ≥ 2 members (D7) | ≥ 45% |
| D1 / D7 / D30 retention | 55% / 35% / 20% |
| Weekly Active Bonds | 5,000 |
| Avg prayers logged per active user per day | ≥ 3.5 |
| Nudge → prayer logged within 30 min | ≥ 40% |
| Play Store rating | ≥ 4.6 |
| Crash-free users | ≥ 99.5% |

**Guardrail metrics** (watch for harm): nudge mute rate, bond leave rate, and "felt judged" in-app survey responses.

---

## 15. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Feels like surveillance between spouses | Users churn, relationship harm | Privacy-by-default, hide timing, easy leave/mute, no free-text in MVP |
| Riya / showing off | Ethical and brand risk | No public stats, "we" framing, sincerity reminders, scholar review |
| Inaccurate prayer times | Trust destroyed | Use the proven `adhan` lib, per-country defaults, manual offsets, beta test across regions |
| Post-Ramadan drop-off | Retention cliff | Shawwal/Dhul Hijjah challenges, weekly Jumu'ah summary, streak shields |
| Aggressive OEM battery killers block notifications | Core loop breaks | Exact alarms, onboarding education, dontkillmyapp-style guides |
| Abuse/harassment through nudges | Safety risk | Preset-only nudges, rate limits, block/report |
| Minors using the app | Child-safety risk | 13+ age gate in MVP. Family mode only after a dedicated safety design in v2 |
| Religious disagreement (madhab differences) | Negative reviews | Configurable methods, neutral wording, cite sources |
| Solo founder bandwidth | Delayed launch | Strict MVP cut, Firebase managed backend, defer the Quran reader and iOS |

---

## 16. Roadmap Detail (post-MVP)

### v1.1 Ramadan
- Fasting tracker (including excused days, discreet)
- Taraweeh and Tahajjud tracking
- **Shared Quran Khatm** (juz claiming)
- Suhoor/Iftar countdown and notifications
- Last 10 nights mode + Laylatul Qadr du'a reminder
- "30 days together" Ramadan bond badge

### v1.5
- Custom habits (sadaqah, sunnah fasts Mon/Thu, duha prayer, witr)
- **Du'a request wall** inside a bond ("Make du'a for my exam"), with an "I made du'a for you 🤲" response
- Widgets 2.0 (Together arc widget, partner status)
- Qibla compass
- Arabic, Urdu, Indonesian, Malay, Turkish
- Monthly reflection journal (private)

### v2.0
- **iOS launch** (WidgetKit, Live Activities for the next prayer)
- Rafiq Plus subscription
- Family mode (parent ↔ child, child-safe, reward stickers)
- Wear OS tasbih counter, smart-ring tasbih integrations
- Masjid/halaqa "community circles" (larger, admin-managed)
- Mentor bonds for reverts (with mosque partner programs)

### Explicitly out of scope (for now)
Public feeds, followers, leaderboards, free-text chat, Quran reader/audio, fatwa or Q&A features, ads.

---

## 17. MVP Build Plan (solo dev, ~8 weeks)

| Week | Deliverable |
|---|---|
| 1 | Project setup, theming, router, Firebase, auth, onboarding UI |
| 2 | Prayer time service, local notifications with action buttons, exact alarms |
| 3 | Local DB, prayer logging, solo dashboard, offline sync queue |
| 4 | Bonds: create/join/invite code, App Links, Firestore rules |
| 5 | Together dashboard + arc animation, Cloud Function aggregations, streaks |
| 6 | Nudges + du'a reactions + smart nudge scheduler, FCM |
| 7 | Dhikr counter + shared dhikr goals, 2x2 widget, Bangla localization |
| 8 | Polish, analytics, Crashlytics, closed beta release on Play Console internal testing |

---

## 18. Open Questions

1. Final name and trademark/domain check (Rafiq is a common word, so check Play Store conflicts).
2. Should the **smart nudge** be on or off by default? Plan: A/B test it in beta.
3. Should Isha's end be at midnight or Fajr by default? It depends on madhab, so ask in onboarding or default by country.
4. Does excused mode need any partner-visible state at all, or should it be completely invisible?
5. Firebase or Supabase? (Recommendation: Firebase for MVP speed and FCM integration.)
6. Who will be the religious content advisor? Find one before beta.
7. Confirm the Ramadan 2027 start date and lock the launch date.

---

## Appendix A: Sample Nudge Presets

- "Asr is ending soon, let's pray 🤍"
- "Fajr together tomorrow? I'll wake you 🌅"
- "Proud of you, MashaAllah ✨"
- "Let's finish our dhikr goal today 📿"
- "Thinking of you, making du'a for you 🤲"
- "Small steps count. Let's catch the next prayer together."

## Appendix B: Together % Example

Duo: Ayesha tracks 5 prayers + adhkar (6 items) and completed 6. Rafi tracks 5 prayers (5 items) and completed 3.
Together = (6 + 3) / (6 + 5) = **82%**. The headline shows 82%. Individual breakdown shows only if both shared at Basic+, as dots, not fractions.
