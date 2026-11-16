# Suhbah Design System

The visual source of truth for the app. Approved design: **Crescent Split, Islamic touch**.
Reference mockup: `design/home-crescent-split-islamic.html` (open it in a browser).
Earlier explorations in `design/` are archived and are **not** the direction.

## Feel

Calm, lively and clearly made for Muslims, without decoration for its own sake.
The Islamic character comes from a few quiet details (geometric pattern, eight-point star, Hijri date, arch shape), never from labels or ornaments sprinkled everywhere.

**Never do** (the founder rejected these):
- Arabic words placed after every English title
- Star or ornament bullets before titles
- Dotted ornament lines under headings
- Star-shaped buttons
- Cream, ivory or gold page backgrounds
- Red X's, "you missed", or anything that shames
- A moon/crescent as the app logo (the wordmark alone is the brand)
- The star pattern below the top bar (it sits only behind the status bar and top bar)

## Color

| Token | Hex | Use |
|---|---|---|
| `bg` | `#FCFDFC` | Screen background (near white) |
| `card` | `#FFFFFF` | Card surface |
| `line` | `#E4EBE8` | Card borders, dividers, empty tracks |
| `ink` | `#11201B` | Primary text, FAB |
| `sub` | `#6B7C75` | Secondary text, labels |
| `pill` | `#E8F2EE` | Pill backgrounds, active tab |
| `pillInk` | `#0B6F63` | Text on pills |
| `memberA` | `#0E9F8E` | Default color of the current user (teal) |
| `memberB` | `#FF355E` | Default color of the partner (radical red) |

- Member colors are chosen from 10 named shades (`lib/core/member_colors.dart`): Jade #0E9F8E, Pomegranate #FF355E, Saffron #F2A20C, Lapis #2A55C9, Fig #9B4DCA, Olive #8FA33A, Rose #F08CC0, Sky #4AA8F0, Midnight #182447, Date #7A4A2C. Every pair is clearly distinct (tested). The picker shows them as **arch-shaped tiles with names**, never plain round dots; the chosen tile lifts with a soft colored shadow.
- **Same-color handling**: when joining, colors too close to the partner's are shown as "taken" and the joiner must pick another. If a clash still happens later, each phone shows the partner in the palette color most different from yours (display only, nobody's choice is overwritten).
- **Not done yet** = the member's own color at 20–22% opacity. Never grey-out to a warning color.
- **Upcoming** (prayer not yet due) = transparent with a 1.5px member-colored outline at 60% opacity.
- The geometric pattern uses `memberA`/teal stroke at ~32% opacity.

## Typography

| Role | Font | Notes |
|---|---|---|
| Display | Bricolage Grotesque 800 | Big number (78px, letter-spacing -4%), section titles (17px), logo (700) |
| Body / UI | Plus Jakarta Sans 400–700 | Everything else |
| Labels | Bricolage 700–800, uppercase, letter-spacing 0.14em | "PERCENT", "TOGETHER TODAY", yesterday pill |

## Home screen (top to bottom)

1. **Header**: "suhbah" wordmark (Bricolage 800, 24) with the full date under it in `sub` ("Monday · 16 November"). On the right, a **streak pill**: a warm amber flame (one hue for everyone, gradient #FFB524 → #FF6B1A, never the member colors) and the number in deep amber on a soft amber pill (#FFF3E3). At 0 it's an outlined grey flame on a white pill with a `line` border. While the streak still waits on today, the flame is softened to 55%. Tap opens the week of flames.
2. **Background pattern**: the tiled eight-point star sits only behind the status bar and the name/date/streak bar (70px below the status bar), and scrolls away with the page. Same on Today, Journey and Me.
3. **Together arc** (the hero): fills the content column inside the 16px page margins plus 4px each side (max 420), sitting 14px under the header (max 440). There is no separate next-prayer strip: the Salah card's meta ("Isha at 6:31 PM") already says what's next, and tapping the Salah card outside its shapes opens **Prayers today** (the five times, who prayed each, the countdown on the next one, the partner's times, and a "Change location or method" link). Three concentric half-circle rows of dots (23 / 20 / 17 dots, radius 132 / 115 / 98, dot r 6.6). Left half = current user, right half = partner, each filling from the base up. The center-top dot fills only when both reach 100%.
   - Curved label "TOGETHER TODAY" (solo: "MY DAY TODAY") with a small eight-point star above it.
   - The big number and "PERCENT" sit at the base.
   - The dimmed arc is always drawn. On open, both sides fill **at the same time** to their own progress (~1.4s, ease-in-out); later changes animate from the old value. Respect reduced motion.
4. **Legend**: a colored dot and name for each member.
5. The **streak** lives only in the header pill and its sheet (seven flames for the last 7 days: lit at 60%, today outlined and pulsing until it counts, "Reach 60% today to make it 13" / "Today counts" / "Today can be day one", plus "Yesterday 74%"). There is no streak card or sun-path card on Today.
6. (spacing) The arc sits 26px under the next prayer line so the top reads as one calm block.
7. **Today's Progress** title, a "+N BONUS" pill when bonus deeds are ticked, and a status line with prayer counts ("Prayers so far: you 3, Rafeed 4 of 5"); it never repeats the next prayer. Then the Salah card, and Quran + Istighfar side by side.
   - **Salah** (full width): "waqt shapes", five skewed segments per member mirrored around a small crescent in a circle. Left skews -10°, right +10°. Labels F D A M I under each side (mirrored on the right).
   - Quran and Istighfar share one skeleton so they line up row by row: header (title + meta), a 58px picture, the two counts ("10/10  10/10" in member colors), then the action pill.
   - **Quran** (half): an open book, two pages (left me, right partner) filling bottom-up toward 10 ayat, then the values and a "+5 ayat" pill. Each tap adds 5.
   - **Istighfar** (half): a **tasbih** per member: 33 beads on a loop with the leading bead and a small tassel at the bottom. Beads fill in the member color (a third of the loop per round of 33; full at 100), and the leading bead and tassel turn solid at 100. Then the counts and a pill that steps 33 → 66 → 100 ("Done today" after).
8. **Good deeds** ("Bonus. They never change your 100%."):
   - The user's chosen cards in a 2-column grid: Fasting, Sadaqah, Dua for each other (paired only), Call family & friends. Each card shows its icon and title, then one mark per member **shaped by the deed**: a pill with a sunset for Fasting, a round coin with a giving hand for Sadaqah, a pill with open hands for Dua, a round tile with a phone for Family. Solid member color with a white symbol when done, a pale fill with a faint outline when not, and "Gave sadaqah" / "Tap when done".
   - No dashed tile: a small pill button at the right of the "Good deeds" title says "+ Add" (no cards yet) or "Edit", and opens the card sheet (also in Me → Home cards). With no cards the section is just the title row.
   - During Ramadan, a dark "Ramadan Mubarak · Add Fasting to your day?" banner appears until it's added or dismissed for that year. Fasting is listed first with a RAMADAN tag only during Ramadan.
9. **Today's reminder**: a `pill` card with a small star, "TODAY'S REMINDER", one short ayah or hadith (Bricolage 17) and its source. The same for everyone on a date.
10. **Log button** beside the dock (see Navigation). The quick-log sheet also lists the Good deeds as chips.

## Navigation

A **floating dock** (Material 3 expressive floating toolbar) sits above the bottom edge: white, 32px radius, `line` border, soft shadow. Three tabs: **Today · Journey · Me**. The selected tab grows into an `ink` pill with a white icon and its name; the others shrink to a grey icon. On Today a 64px `ink` rounded-square **+** sits beside the dock (opens "Log a deed"). Scroll content leaves 120px at the bottom for it.

## Other tabs

Every tab speaks the home language: dots, the arch / waqt shape, the eight-point star as the single accent mark, and the two member colors side by side (you left, partner right). Shared frame: star pattern on top, 30px Bricolage title with a `sub` line, white 18px cards, small uppercase section labels.

- **Today cards log directly**: Quran adds **+5 ayat** per tap; Istighfar steps **33 → 66 → 100** (the last tap adds 34 so it lands on 100, then 33s after). There is no separate Dhikr tab.
- **Journey** (top to bottom): streak hero with a two-color star badge; "This week" with 7 dots per person per day; "Worth knowing" with at most 3 plain sentences that only appear when there is enough data (most-kept prayer, the one with the most room, the fullest weekday after 14 active days); "Last 30 days, side by side" on a center spine (you fill left, partner right) for each prayer, ayat and istighfar; a **History** card with the last 14 days as split dots that opens the full history.
- **History**: a month calendar of split dots (your half, partner's half), with month arrows going back up to a year. Tap a day for its detail: each prayer as a pair of waqt marks (who prayed), ayat and istighfar for both, and a check badge for whoever completed the day.
- **Me**: suhbah hero (both avatars sealed by a two-color star; dashed empty seat when solo), prayer times as arch tiles, then Profile, Partner and Account rows. Calculation method and Asr school are changed here, not in onboarding.

## Onboarding

Steps slide in, and each step's eyebrow, title, subtitle and content fade up in sequence. Step dots sit at the top right (current step drawn as a small arch). The primary button says what happens next ("Continue as Ornob", "Saffron it is", "Looks right").
1. **Name**: eyebrow "Assalamu alaikum". A large live avatar updates as you type; a chip offers the first word if you type two.
2. **Color**: eyebrow "Nice to meet you, {name}". A small arc labelled with your name refills in each color you tap; arch tiles below.
3. **Location**: eyebrow "Almost there". Only "Use my location" or city search. Method and Asr are picked automatically from the country and shown in one line under today's times ("You can change this anytime in Me").
4. **Pair**: eyebrow "Last step", title "Better together". "Invite someone" is the dark primary option; "I have a code"; "Start on my own". Under them, the hadith about close friends (Sunan Abi Dawud).

## Surfaces
- Menus: white, 18px radius, `line` border, soft shadow, icon + label rows.
- Dialogs: white, 26px radius, Bricolage title, `sub` body, text Cancel + black filled confirm.
- Sheets: white, 28px top radius, drag handle, Bricolage title + `sub` subtitle. "Log a deed" uses arch-topped prayer tiles that fill with the member color, and stepper rows for Quran and istighfar.
- Snackbars: floating, `ink`, 14px radius.

## Solo mode

No partner: both halves of the arc use your color and fill together from your one score. Label reads "MY DAY TODAY", the legend shows only you, the Salah card shows one row of waqt shapes, and the Quran/Istighfar cards show only your numbers.

## Scoring

Each person's 100% = **5 prayers + 10 ayat of Quran + 100 istighfar** (7 goals).
- Each prayed prayer = 1 goal. Quran = verses/10. Istighfar = count/100 (both capped at 1).
- Person % = sum / 7. Together % = average of members' %.
- Example: Ayesha 6/7, Rafi 4/7 → together 71%.

## Copy tone

Gentle, "we" framing, no guilt. See PRD §11.


## Update 2026-11-16
- Top-of-screen background: a faint arcade of pointed arches (46px bays, double outline at 20%/10% of the brand green) over a soft #EDF5F1 wash, fading out before content. Islamic by suggestion, not by symbol. No star tiles.
- Color picker: rounded-square swatches (radius 13) with names; selected gets a 2px ink outer ring and a check. No domes, no stars.
- Invite: code card with Copy code (code only), plus Share invite and Show QR tiles. When the partner joins: two-avatar card in both colors, confetti in both colors, haptic.
- Emoji: no heart emoji in copy. Celebrate with words (MashaAllah) or the member colors.
- Dialogs: 20px side inset, helper text wraps to 2 lines.
- Palette v2: Emerald 0B7D5E, Pomegranate C7224F, Saffron E9A21B, Lapis 2445B8, Amethyst A040A8, Turquoise 3CC2C4, Olive 7F8F2A, Rosewater E58BB0, Midnight 1C2A4D, Oud 743C0A. Old values map to these on read.
- Accidental taps: holding a Quran or Istighfar card (or its pill) opens an adjust sheet: big count, 'Undo last tap', −/+ steppers, Reset to 0. Cards stay clean: no undo button, no undo toasts.
- Good deeds history: Journey shows a 'Good deeds · last 30 days' card only if the person has a deed card or logged a deed; day detail lists deeds with a dot per person.
- Onboarding v3 (design/onboarding-redesign.html): Welcome → You → Your half → Prayer times → Your suhbah → All set. Progress is small arches that fill from the bottom. Every step shows its result live (avatar, half arc, sun path, seats). The finish screen is the only place `onboarded` is set.
- Motion: tab switches fade and rise (320ms); page sections stagger in once; numbers pop when they change. All of it is skipped when the system asks for reduced motion.
- Haptics: tick (selection, each ~2 dots while the arc fills, sheet opens), tap (logging), press (hold, reset, confirm), success (arc reaches 100%, partner joins), partner (soft double knock when your partner logs while you watch). Uses system touch feedback, so it follows the phone's setting.

## Brand mark and app icon (final, 2026-11-17)
- Mark: the together arc as three strokes (radii 33 / 23.5 / 14, stroke 7, 3.2 gap at the top on a 108 grid), split into two halves. Left Ink Emerald `#12A679`, right Pomegranate `#C7224F`.
- Default ground is white `#FFFFFF` everywhere (launcher, splash, store, web). Dark variation on `#0C1814` is for dark-mode splash and dark surfaces only.
- In app: `SuhbahMark` (lib/core/brand.dart) beside the wordmark on Today, on the splash and retry screens, and in Me's footer.
- Source files: design/brand/final (SVG masters, 1024 PNGs, 512 Play icons, mark in colour/white/ink, horizontal lockups). Regenerate all platform sizes with the script noted in CLAUDE.md.
- Never: recolour one half only, add the star back on top, put the arc on a busy photo, or stretch it.
