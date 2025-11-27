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
