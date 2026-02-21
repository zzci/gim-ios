# GIM iOS Audit Report - Iteration 2

**Date:** 2026-02-21
**Scope:** SEC-005 (ATS), SEC-006 (Keychain), L10N-001 (Localization)
**Project:** GIM iOS (fork of Element X iOS)
**Bundle ID:** `im.g.message`

---

## SEC-005: App Transport Security (ATS) Configuration Audit

**Priority:** P1
**Risk Level:** LOW (Good)

### Findings

1. **No ATS exceptions configured.** Neither `Info.plist` nor `target.yml` contains any `NSAppTransportSecurity`, `NSAllowsArbitraryLoads`, or `NSExceptionDomains` keys. This means iOS enforces the strictest default ATS policy: all network connections must use HTTPS with TLS 1.2+ and valid certificates.

2. **No plaintext HTTP URLs in source code.** A search of all Swift source files under `ElementX/Sources/` for `http://` string literals returned zero results. All server URLs (homeserver, OIDC, website, push gateway) use `https://`.

3. **Relevant URL configurations verified as HTTPS:**
   - `websiteURL` = `https://g.im` (in `AppSettings.swift`, line 193)
   - `oidcRedirectURL` = `im.g.message://oidc/callback` (custom scheme, not HTTP -- this is correct for OIDC redirect via `ASWebAuthenticationSession`)
   - Associated domains in `target.yml`: `applinks:g.im`, `webcredentials:g.im` (AASA requires HTTPS by design)
   - Push gateway and homeserver URLs are configured as HTTPS in AppSettings

4. **NSE and ShareExtension** also have no ATS exceptions in their respective `Info.plist` and `target.yml` files.

5. **Debug proxy configuration** uses `HTTPS_PROXY` environment variable set to `localhost:9090`, but this is disabled by default (`isEnabled: false` in `target.yml` line 24) and only applies to debug builds.

### Risk Assessment

| Check | Status | Notes |
|-------|--------|-------|
| NSAllowsArbitraryLoads | Not present (PASS) | iOS default enforces HTTPS |
| NSExceptionDomains | Not present (PASS) | No domains exempt from ATS |
| HTTP URLs in source | None found (PASS) | All URLs use HTTPS |
| g.im communications | HTTPS enforced (PASS) | Via default ATS + explicit HTTPS URLs |
| Debug proxy | Disabled by default (PASS) | Only active when manually enabled |

### Recommendations

- **No action required.** The ATS configuration is optimal -- iOS default ATS enforcement is active with no exceptions. All g.im communications will use HTTPS.
- **Optional hardening:** Consider adding an explicit `NSAppTransportSecurity` dict with `NSAllowsArbitraryLoads: false` to make the security posture self-documenting, though this is not functionally necessary (it matches the default).

---

## SEC-006: Keychain Access Control and Data Classification Audit

**Priority:** P1
**Risk Level:** MEDIUM (Actionable findings)

### Findings

#### 1. Keychain Architecture

The app uses the `KeychainAccess` third-party library (Swift wrapper around Security framework) via a centralized `KeychainController` class.

**File:** `/ElementX/Sources/Services/Keychain/KeychainController.swift`

Two separate Keychain service instances are used:
- **`restorationTokenKeychain`**: Stores session restoration tokens (access tokens, refresh tokens, OIDC data, encryption passphrase) keyed by user ID.
- **`mainKeychain`**: Stores app-lock PIN code and biometric state.

Service identifiers follow the pattern:
- Restoration tokens: `im.g.message.sessions` (derived from `InfoPlistReader.main.baseBundleIdentifier + ".sessions"`)
- Main keychain: `im.g.message.keychain.sessions` (derived from `baseBundleIdentifier + ".keychain.sessions"`)

#### 2. Keychain Access Group

- **Access group:** `$(DEVELOPMENT_TEAM).$(BASE_BUNDLE_IDENTIFIER)` = `7J4U792NQT.im.g.message`
- This is correctly shared across the main app, NSE, and ShareExtension (all three targets reference `$(KEYCHAIN_ACCESS_GROUP_IDENTIFIER)` in their entitlements).
- The `KeychainController` includes a `resolveAccessGroup` method that gracefully handles sideloaded/re-signed builds where the team ID may differ -- good defensive practice.

#### 3. Keychain Accessibility Level -- FINDING

**The `kSecAttrAccessible` level is NOT explicitly set.** The `KeychainAccess` library defaults to `kSecAttrAccessibleAfterFirstUnlock` when no accessibility is specified. While this is a reasonable default, it is not the recommended level for highly sensitive OIDC tokens.

The restoration token contains:
- `accessToken` (string) -- OAuth access token
- `refreshToken` (string, optional) -- OAuth refresh token
- `oidcData` (string, optional) -- OIDC session data
- `passphrase` (string) -- encryption passphrase for session data
- `userId`, `deviceId`, `homeserverUrl` -- session metadata
- `sessionDirectories` -- file paths

**Recommendation:** Set accessibility to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for the restoration token keychain, and `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for the PIN code keychain. The `ThisDeviceOnly` variants prevent keychain items from being included in iCloud backups, which is critical for OIDC tokens and PIN codes.

Example fix in `KeychainController.init`:
```swift
restorationTokenKeychain = Keychain(service: service.restorationTokenID, accessGroup: resolvedGroup)
    .accessibility(.afterFirstUnlockThisDeviceOnly)
mainKeychain = Keychain(service: service.mainID, accessGroup: resolvedGroup)
    .accessibility(.whenUnlockedThisDeviceOnly)
```

#### 4. Sensitive Data in UserDefaults -- PASS

A thorough search of `AppSettings.swift` `UserDefaultsKeys` reveals that NO sensitive credentials are stored in UserDefaults. The keys stored are exclusively:
- UI preferences (appearance, timeline style)
- Feature flags (boolean toggles)
- Onboarding state (has-seen flags)
- Notification settings
- Analytics consent state
- Log level configuration
- App lock attempt counters (integer, not the PIN itself)

The PIN code itself is correctly stored in the Keychain (`mainKeychain`), not UserDefaults.

#### 5. PIN Code Storage

The PIN code is stored as a plain string in the Keychain via `mainKeychain.set(pinCode, key: "appLockPINCode")`. While the Keychain provides encryption at rest, the PIN is not hashed before storage.

**Risk:** Low. The Keychain provides strong encryption. However, if Keychain data were ever extracted (jailbroken device), the PIN would be immediately usable. Storing a salted hash instead would add defense-in-depth.

### Risk Assessment

| Check | Status | Notes |
|-------|--------|-------|
| Tokens in Keychain | PASS | All OIDC/session tokens stored in Keychain |
| Tokens in UserDefaults | PASS | No sensitive data in UserDefaults |
| Access group correct | PASS | `7J4U792NQT.im.g.message` shared across targets |
| Accessibility level | WARNING | Not explicitly set; defaults to `afterFirstUnlock` (no `ThisDeviceOnly`) |
| PIN code storage | INFO | Stored as plaintext string (not hashed) |
| Keychain sharing | PASS | Correctly shared between app, NSE, ShareExtension |
| Sideload resilience | PASS | `resolveAccessGroup` handles re-signed builds |

### Recommendations

1. **HIGH: Set explicit Keychain accessibility levels.** Add `.accessibility(.afterFirstUnlockThisDeviceOnly)` to the restoration token keychain and `.accessibility(.whenUnlockedThisDeviceOnly)` to the main keychain. This prevents tokens from being included in iCloud/iTunes backups.

2. **MEDIUM: Hash the PIN code before storage.** Use `SHA-256(salt + PIN)` and store the hash. Verify by hashing input and comparing. This adds defense-in-depth against Keychain extraction on compromised devices.

3. **LOW: Add Keychain data protection class documentation.** Document the chosen accessibility levels and rationale in a security architecture doc or code comments.

---

## L10N-001: GIM Localization Workflow Evaluation

**Priority:** P2
**Risk Level:** LOW

### Findings

#### 1. Localization File Structure

The localization files are located at `ElementX/Resources/Localizations/` with the following language directories:

| Language | Directory | Localizable.strings | Localizable.stringsdict | SAS.strings | InfoPlist.strings |
|----------|-----------|---------------------|------------------------|-------------|-------------------|
| English (base) | `en.lproj` | 1539 keys | 549 lines | 63 lines | 5 keys |
| Simplified Chinese | `zh-Hans.lproj` | 1539 keys | 491 lines | 63 lines | 5 keys |
| Traditional Chinese (TW) | `zh-Hant-TW.lproj` | 1539 keys | (present) | (absent) | 5 keys |

**Key observation:** The upstream Element X iOS project supports ~40 languages. GIM has stripped this down to only English and Chinese (Simplified + Traditional TW), which is appropriate for its target audience.

#### 2. Translation Coverage

- **Localizable.strings:** Both zh-Hans and en have identical key counts (1539 keys each). Coverage is 100%.
- **Localizable.stringsdict:** zh-Hans has 491 lines vs en's 549 lines (89% coverage). The difference is expected because Chinese does not have plural forms like English, so fewer plural rule entries are needed.
- **SAS.strings:** Identical coverage (63 lines each) for en and zh-Hans.
- **InfoPlist.strings:** Both languages have 5 keys with GIM branding ("GIM" instead of "Element").

#### 3. Remaining "Element" References in Translations

Both English and Chinese Localizable.strings still contain references to "Element" in 6-7 string values:
- `call_invalid_audio_device_bluetooth_devices_disabled` -- references "Element Call"
- `screen_advanced_settings_element_call_base_url` -- references "Element Call"
- `screen_change_server_error_element_pro_required_*` -- references "Element Pro"
- `screen_room_timeline_legacy_call` -- references "Element X"
- `screen_onboarding_welcome_title` (zh-Hans only) -- references "Element"

These come from the upstream Localazy-managed translations and cannot be overridden via `Untranslated.strings` without forking the translation pipeline.

#### 4. Untranslated.strings (GIM Overrides)

The `Untranslated.strings` file contains:
- A test string (`"untranslated"`)
- Soft logout flow strings (7 keys) -- English only, not GIM-specific
- Screen recording protection string (1 key)

This file is the recommended place for GIM-specific string overrides that should not go through Localazy. Currently, no GIM branding overrides are present here.

#### 5. Localazy Configuration

The project has a `localazy.json` configuration file at the project root with:
- A read-only key for pulling translations
- Conversion rules that output to the iOS `.strings` and `.stringsdict` formats
- No write key present (cannot push new strings upstream)
- The config is inherited from Element X and pulls from the shared Element translation project

**Implication:** GIM cannot independently manage translations via Localazy without its own project. The current setup is read-only.

#### 6. Traditional Chinese (zh-Hant-TW) Gap

zh-Hant-TW is missing `SAS.strings` entirely. This means emoji verification descriptions will fall back to English for Traditional Chinese users.

### Recommended Localization Workflow for GIM

#### Short-term (Now)

1. **Override Element-branded strings in `Untranslated.strings`.** Add GIM-branded versions of the 6 strings that reference "Element Call", "Element Pro", "Element X". Since `Untranslated.strings` takes precedence over `Localizable.strings`, this is the cleanest approach.

2. **Add Chinese translations to `Untranslated.strings`.** Create `zh-Hans.lproj/Untranslated.strings` and `zh-Hant-TW.lproj/Untranslated.strings` with Chinese translations of the overridden strings.

3. **Add missing `SAS.strings` to zh-Hant-TW.** Copy from zh-Hans or translate separately.

#### Medium-term (Next Quarter)

4. **Set up a standalone Localazy project for GIM.** Fork the Element translations as a base, then manage GIM-specific strings independently. This gives full control over branding and allows community contributors to help with translations.

5. **Add Hong Kong Traditional Chinese (zh-Hant-HK)** if targeting Hong Kong users.

#### Long-term

6. **Consider adding Japanese and Korean** if expanding to broader East Asian markets.

7. **Automate string extraction** -- set up CI to detect new untranslated strings and flag them for review.

### Risk Assessment

| Check | Status | Notes |
|-------|--------|-------|
| Chinese translation coverage | GOOD | 100% key coverage for zh-Hans |
| GIM branding in translations | WARNING | 6-7 strings still reference "Element" |
| Localazy independence | WARNING | Read-only config, tied to Element project |
| zh-Hant-TW completeness | INFO | Missing SAS.strings |
| InfoPlist.strings branding | PASS | Correctly branded as "GIM" in both languages |

---

## Summary

| Task | Risk | Key Finding | Action Required |
|------|------|-------------|-----------------|
| SEC-005 (ATS) | LOW | No ATS exceptions; all connections enforce HTTPS | None (optimal) |
| SEC-006 (Keychain) | MEDIUM | Keychain accessibility not explicitly set; tokens may be included in backups | Set `ThisDeviceOnly` accessibility |
| L10N-001 (Localization) | LOW | Good Chinese coverage; 6 Element-branded strings remain | Override in Untranslated.strings |

### Priority Actions

1. **[HIGH]** Set explicit Keychain accessibility to `afterFirstUnlockThisDeviceOnly` for restoration tokens
2. **[MEDIUM]** Override remaining Element-branded strings in Untranslated.strings for both en and zh-Hans
3. **[LOW]** Add missing SAS.strings to zh-Hant-TW
4. **[LOW]** Consider hashing PIN code before Keychain storage
