# Suhbah (صُحْبَة, "companionship")

A shared worship tracker for Muslims. Two people (or a small circle) log prayers, Quran and istighfar, and see one combined "together" arc. Android first, Flutter.
Package: `com.ornobaadi.suhbah`. App label "Suhbah"; wordmark lowercase "suhbah"; Arabic صُحْبَة. In copy the partner may be called "your Rafiq".

## Read first
- `PRD.md`: product requirements (long version; the founder is cutting it down to a ~1 week build).
- `DESIGN.md`: the approved visual design. **Follow it exactly for all UI work** and check its "Never do" list.
- `design/home-crescent-split-islamic.html`: the approved home screen mockup.

## Current scope (MVP, kept deliberately simple)
- 100% per person = 5 prayers + 10 ayat + 100 istighfar.
- Flow: Google sign-in → nickname → color → location → invite partner / join with code / solo → home.
- Firebase Auth (Google) + Firestore only, free Spark plan, no Cloud Functions. Firestore's offline cache handles "save now, sync when online"; live listeners update the partner's screen.
- Prayer times are always calculated on-device with `adhan` from the user's location/timezone. Never placeholders.
- Data: `users/{uid}` (profile, pairId), `users/{uid}/days/{yyyy-MM-dd}` (prayed, ayat, istighfar), `pairs/{code}` (members, ownerName, ownerColor). Rules in `firestore.rules`.

## Code layout
```
lib/
  main.dart
  core/theme/        colors, text styles (from DESIGN.md)
  core/              shared utils
  data/              models + local state
  features/home/     home screen and its widgets
```
  core/prayer_times.dart   adhan wrapper, method/Asr suggestions by country, city list
  core/member_colors.dart  palette, color distance, partner fallback color
  data/repository.dart     all Firebase calls
  data/today_provider.dart Riverpod providers + TodayActions
  features/onboarding/     sign in, onboarding flow, pair screen, location_form
  features/insights/       Journey tab, history calendar, day widgets
  data/insights.dart       "Worth knowing" sentences (pure, tested)
  features/me/             settings tab, account_actions (shared with header menu), prayer settings
  core/ramadan.dart        Ramadan date table, isRamadan()
  core/reminders.dart      daily ayah/hadith list (founder to review)
  core/ui.dart             shared cards, settings rows, dialogs, sheets, toast
- State: `flutter_riverpod` (no code generation).
- Fonts: `google_fonts` (Bricolage Grotesque, Plus Jakarta Sans).
- Google sign-in goes through `firebase_auth` directly (popup on web, `signInWithProvider` on Android). No `google_sign_in` package.
- `lib/firebase_options.dart` is a placeholder until `flutterfire configure` is run.

## Commands
- `flutter pub get`
- `flutter analyze`
- Run modes (founder's convention):
  - Dev testing: `flutter run -d chrome --profile` (or `-d <android-device> --profile`)
  - Release: `flutter run -d chrome --release` / `flutter build apk --release`
  - Debug with hot reload: `flutter run -d chrome`
- Chrome lives at `C:\Program Files\Google\Chrome\Application\chrome.exe`. If Flutter doesn't list Chrome, set `CHROME_EXECUTABLE` to that path.

## Working rules
- After every change, update the **Progress log** below (date, what changed). Keep entries to one line.
- If a design decision changes, update `DESIGN.md` in the same change.
- No shame language, no red X's, missed = pale member color.

## Progress log
- 2026-11-15: PRD written. Home design explored (5 + 5 + 5 variations); Crescent Split with Islamic touch approved. DESIGN.md and CLAUDE.md added.
- 2026-11-15: Home screen built in Flutter (theme, together arc, star pattern, Salah/Quran/Istighfar cards, quick-log sheet, Riverpod local state, partner = sample data). Scoring test passes. Bottom nav height fixed; founder confirmed it looks right in Chrome (profile build).
- 2026-11-15: Arc animation reworked: dim layout always visible, both sides fill together to their own % on open and on every change.
- 2026-11-15: Sign-in, onboarding (nickname, color, location, pair/solo), Firestore sync, solo mode, real prayer times (adhan), Gregorian date, menu (invite, edit nickname, leave pair, sign out), security rules. Analyze clean, 6 tests pass. Waiting on Firebase project setup to test end to end.
- 2026-11-15: Name finalized as Suhbah. Renamed everything to `com.ornobaadi.suhbah` (applicationId, Kotlin package, Dart package, wordmark, invite copy, all platforms).
- 2026-11-15: Firebase configured (project suhbah-companion), firebase.json + .firebaserc added for rules deploy.
- 2026-11-15: Guest mode (anonymous auth) + "Sign in with Google to save" upgrade via account linking, same uid.
- 2026-11-15: App completed and polished: Dhikr (tap ring, undo, partner count), Insights (streaks, week bars, 5-week calendar, prayer consistency, totals), Me (profile, color, partner, prayer settings, Google link, sign out, delete account); themed menus/dialogs/sheets/snackbars; quick-log sheet redesigned; taps batched into one write; LocationForm shared by onboarding and settings.
- 2026-11-15: Added test/logic_test.dart (17 tests: scoring caps, broken docs, streaks incl. pairs and month edges, undo clamp, batched taps, all calc methods, color fallback for every pair, tap ring, taken colors). 23 tests pass. Founder runs builds/previews manually; Claude only runs analyze + tests.
- 2026-11-15: Redesigned Dhikr (tasbih bead ring, partner inner ring, rounds, together bar), Insights (star streak hero, dot-week, split-dot calendar, 30-dot salah rows), Me (suhbah hero, waqt-tile prayer times), onboarding step dots + live color arc. Added test/screens_test.dart (12 layout tests); fixed 2 overflows it found. 35 tests pass.
- 2026-11-16: Mockups for Insights + Settings, 5 directions (design/insights-settings-variations.html): Month Arc, Waqt Board, Stories, Side by Side, Touch Calendar. Awaiting founder pick; app code unchanged.
- 2026-11-16: Founder feedback pass: playful onboarding (entrance animations, live avatar, eyebrows, location without method/Asr), "Better together" pairing, 10 named arch color tiles, Dhikr tab removed (Quran +5, Istighfar 33/66/100), floating dock Today/Journey/Me, Journey tab rebuilt + full History calendar with day detail. 38 tests pass.
- 2026-11-16: Release APK built (flutter build apk --release, 54 MB). Signed with the debug key for now; a Play upload key is still needed.
- 2026-11-16: Home redesign: one-line header (wordmark + date, no moon/menu/avatar), star pattern only behind the top bar on every screen, next-prayer card with sun path, streak strip with flames, bonus Good deeds cards (fasting/sadaqah/dua/family, never change %), Ramadan banner, daily reminder. Me gets "Home cards". 48 tests pass. Google sign-in on Android needs the debug SHA-1/SHA-256 added in Firebase.
- 2026-11-16: Home top reworked per founder sketch: date under the wordmark, streak as a header pill (sheet with the week), next prayer as a headline line under the header; sun-path and streak cards removed; arc moved down.
- 2026-11-16: Today polish: amber streak flame pill, next prayer as a body-type strip, Quran/Istighfar on one aligned skeleton, Good deeds add/edit as a small header button, star pattern ends at the header.
- 2026-11-16: Deed marks shaped per type (arch/coin/hands/phone), Istighfar as a tasbih ring per member, next-prayer strip opens a "Prayers today" sheet, arc enlarged into the gutters.
- 2026-11-16: Removed the next-prayer strip (Salah card meta covers it; tapping the Salah card opens Prayers today), arc moved up and capped at 440, Fasting and Family marks restyled as pill and round tile.
- 2026-11-16: Top pattern redrawn (whole outlined stars on a staggered grid over a soft tint wash, smooth fade, no stray line ends); invite: Copy code (code only), Share invite (share_plus), Show QR (qr_flutter); paired state turns into a two-avatar card in both colors with confetti and a haptic; white heart emoji removed everywhere; color picker is rounded-square swatches with a selection ring; dialogs are wider with wrapping helper text.
- 2026-11-16: Undo toast after Quran/Istighfar taps; partner-joined confetti + toast on Today the first time a partner is seen (profile field metPartner); new palette (Emerald, Pomegranate, Saffron, Lapis, Amethyst, Turquoise, Olive, Rosewater, Midnight, Oud) with old colors auto-upgraded via storedColor(); top background is now a faint pointed-arch arcade; Good deeds get a Journey section (last 30 days, only for people who use them) and appear in History day detail; fixed Journey dropping today's deeds.
- 2026-11-16: Onboarding rebuilt from design/onboarding-redesign.html: arch progress, new copy per step, color step fills only your half with a note per color, sun path over prayer times, partner seats (dashed seat breathes, fills on join), flip-in invite code, new finish screen (full arc, next prayer, Open Today) that sets onboarded. Fixed blank location step (nested list). test/onboarding_test.dart added; 53 tests pass.
- 2026-11-16: Undo toast replaced by an undo button on the Quran/Istighfar cards (always there once logged; ayatUndo/istighfarUndo take back the last tap) and hold-to-adjust sheet (−/+ and Reset to 0); counts pop on change; tab switches fade/rise; page sections stagger in (Entrance moved to core/ui); color note sits under the swatches; 'Assalamu alaikum, Name!'; AuthGate shows Try again on profile load errors instead of dropping into onboarding. 54 tests pass.
- 2026-11-16: Removed the inline undo button from the Quran/Istighfar cards (founder: misaligned); undo lives in the hold sheet as 'Undo last tap', plus −/+ and Reset to 0. The action pill also opens it on hold.
- 2026-11-16: Haptics vocabulary (core/haptics.dart: tick, tap, press, success, partner). The arc ticks as dots light while filling (never while emptying) and gives a success pulse when it reaches 100%; a partner logging something while you watch gives a soft double knock; partner joined = success; sheets tick on open; confirm buttons press.
- 2026-11-16: Release APK rebuilt (54.6 MB, debug-signed) with new onboarding, hold-to-adjust, haptics, palette v2.
- Web preview: `flutter build web` then `python -m http.server 8085 --directory build/web` (debug `web-server` hangs waiting for a debugger).
- 2026-11-17: App icon explorations rounds 6-8 (dua hands, arc contrast studies, pairs on white) in design/app-icons.html; founder likes arc-only G1 (Emerald + Pomegranate on white). Brand identity draft built with the brand-identity skill in design/brand/suhbah (3 colour sets: A Two Gardens, B Tile and Lamp, C After Isha; board.png). Awaiting founder pick; app code unchanged.
- 2026-11-17: Arc colour playground (design/arc-playground.html, published as an artifact): pick left half, right half and background from every colour used so far or a custom hex, presets from the icon rounds, saved combos, contrast readout.
- 2026-11-17: Final brand: arc mark Ink Emerald #12A679 + Pomegranate #C7224F, white ground default (dark #0C1814 variation). New launcher icons (legacy, round, adaptive with monochrome), Android splash (pre-12 and 12+, white / dark in night mode), iOS AppIcon set, web favicon/icons/maskable, manifest colours + description, CFBundleName Suhbah. lib/core/brand.dart SuhbahMark on Today header, splash, retry, Me footer. Masters in design/brand/final. 54 tests pass.
- 2026-11-17: Founder fixes: Google button has a white G and 'Try it first' sits under it; onboarding step, name and colour saved on device (shared_preferences); location step draws the whole sun path with all five prayers labelled in an even row; 'I'll start on my own' is a text link; invite text carries the Play Store link, QR encodes the Play link with code=, join screen has Scan QR code (mobile_scanner, iOS camera string); Salah card: each prayer column is a big tap target, hold the card for Prayers today, title/meta baseline aligned; back on Journey/Me returns to Today; Me colour sheet saves on tap with a live arc preview; palette +5 (Teal, Terracotta, Ajwa, Dusk, Sidr; swatch test now 80, partner rule still 150). formatter page_width 150. 55 tests pass.
- 2026-11-17: Added the debug keystore SHA-1/SHA-256 to the Firebase Android app (firebase CLI) and refreshed android/app/google-services.json, so Google sign-in works on Android builds signed with this machine's debug key. A Play upload/app-signing key will need its own fingerprints later.
