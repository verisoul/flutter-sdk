## 0.4.70 - 2026-07-23
* Update verisoul/native-android-sdk to version 0.4.72 (collect GPU renderer, CPU core count, and total device RAM in the deviceData telemetry payload)

## 0.4.69 - 2026-07-14
* Update verisoul/native-android-sdk to version 0.4.71 (recover from corrupted DataStore preferences file that made getSessionId() fail permanently with SESSION_UNAVAILABLE on affected devices)

## 0.4.68 - 2026-07-14
* docs: recommend calling configure() before you intend to retrieve a session_id (only initialize if you plan to call the Verisoul API)

## 0.4.67 - 2026-06-26
* Update verisoul/native-android-sdk to version 0.4.70 (clear cached session on project/environment change)
* Update verisoul/native-ios-sdk to version 0.4.69

## 0.4.66 - 2026-06-25
* Update verisoul/native-ios-sdk to version 0.4.68
* Update verisoul/native-android-sdk to version 0.4.69
* docs: remove reinitialize() from README
* Add SDK size to System Requirements in README


## 0.4.65 - 2026-02-06
* docs: update README version to 0.4.65
* chore(ios): keep minimum target at 14.0
* chore(ios): bump VerisoulSDK to 0.4.65


## 0.4.64 - 2026-01-23
* feat: add WEBVIEW_RENDERER_CRASHED error code
* docs: add renderer crash error code
* docs: update README install version to 0.4.64
* chore(android): bump native sdk to 0.4.66

## 0.4.63 - 2026-01-08
* docs: update README install version to 0.4.63
* chore(example): use ENVIRONMENT + API_KEY for authenticate
* chore(ios): bump native sdk to 0.4.64
* chore(android): bump native sdk to 0.4.65
* chore: automatically set sdk_type to flutter during configure


## 0.4.62 - 2025-12-16
* fix: remove mainHandler.post wrapper causing thread conflicts in Android bridges
* test: add unit test demonstrating mainHandler.post deadlock scenario
* test: fix android plugin unit test
* docs: document standardized Verisoul error codes
* docs: enhance documentation structure

## 0.4.61 - 2025-11-27
* chore: update Android SDK to stable version 0.4.61
* fix: add missing WEBVIEW_UNAVAILABLE error code to Android
* fix: remove staging environment (not supported by native Android SDK)
* refactor: standardize error codes across platforms
* fix: remove deprecated jcenter() and upgrade AGP/Kotlin for Gradle 9.0+ compatibility
* chore: add example app lock files for reproducible builds
* feat: upgrade native SDKs and enhance example app test suite
* fix: propagate native SDK error codes through bridge layer


## 0.4.60 - 2025-11-20
* feat: update SDK versions and rewrite example app with comprehensive test suite
* Update README.md
* chore: move version bump scripts to scripts directory


## 0.4.59 - 2025-10-10

- Update verisoul/native-android-sdk to version 0.4.59-beta
- ci: update publish workflow to use official dart-lang action with OIDC auth
- ci: add automated version management and pub.dev publishing workflow
