# Suhbah: Google Play release checklist

## 1. Upload key (once)
1. Run `powershell -ExecutionPolicy Bypass -File scripts\create-upload-key.ps1`. keytool asks for the passwords.
2. Back up `%USERPROFILE%\keys\suhbah-upload.jks` and both passwords somewhere safe (a password manager plus an offline copy). Losing them means asking Google for an upload key reset.
3. Copy `android/key.properties.example` to `android/key.properties` and fill it in. Git ignores `key.properties`, `*.jks` and `*.keystore`.
4. Add the upload key's SHA-1 and SHA-256 (the script prints them) to Firebase: Project settings → Android app → Add fingerprint.

## 2. Build
- Bump `version:` in `pubspec.yaml` for every upload (`1.0.0+1` → `1.0.1+2`; the number after `+` must always grow).
- `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`. Play wants the .aab, not an APK.

## 3. After the first upload
- Play Console → Setup → App signing: copy the **app signing key** SHA-1 and SHA-256 and add them to Firebase too. Without them, Google sign-in fails for people who install from Play.
- Re-download `google-services.json` afterwards (it is fine either way with `signInWithProvider`, but keeps the file current).

## 4. Store listing
- App name: Suhbah
- Short description (80): Pray together, even when apart. Track salah, Quran and istighfar as a pair.
- Full description: describe the shared arc, solo mode, guest mode, no ads.
- App icon: `design/brand/final/play-store-icon-light-512.png`
- Feature graphic: 1024 × 500 still needed.
- Phone screenshots: at least 2 (Today, Journey, Me, onboarding).
- Category: Lifestyle. Contact email: required by Play.

## 5. Policy pages (GitHub Pages from `/docs`)
- Privacy policy: https://ornobaadi.github.io/Suhbah/privacy/
- Account deletion: https://ornobaadi.github.io/Suhbah/delete-account/
- In-app deletion: Me → Delete account (deletes logs, profile, pair membership and the sign-in).
- In-app policy link: Me → Privacy Policy.

## 6. App content forms
**Data safety**
- Data collected: yes. Shared with third parties: no. Encrypted in transit: yes. Users can request deletion: yes (in app + web link above).
- Personal info → Name and Email address (Google sign-in only): collected, for App functionality and Account management, not optional for Google users.
- Personal info → User IDs: collected, App functionality.
- Location → Approximate location: collected, App functionality (prayer times), optional (city search instead).
- App activity → Other user-generated content (prayer, Quran, istighfar logs): collected, App functionality.
- Camera: used only on-device for QR scanning, nothing collected.
- No ads, no analytics, no crash reporting.

**Other forms**
- Ads: No ads.
- Target audience: 13+ (avoid under-13 so Families policy doesn't apply).
- Content rating questionnaire: reference app / lifestyle; no violence, no user-to-user chat (only a shared progress view with one invited person), no location sharing with strangers.
- Permissions: ACCESS_COARSE_LOCATION (prayer times), CAMERA (QR scan, from mobile_scanner).
- Government / financial / health features: none.

## 7. Testing track
New personal developer accounts must run a **closed test with at least 12 testers for 14 days** before production access. Start with Internal testing, then Closed testing.
