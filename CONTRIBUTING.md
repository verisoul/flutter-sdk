# Contributing to Verisoul Flutter SDK

Thank you for your interest in contributing to the Verisoul Flutter SDK!

## Releasing

The release process is fully automated via GitHub Actions. Follow these steps:

### 1. Bump Native Platform Versions

Update the Android and iOS SDK versions as needed:

```bash
make bump-android    # Updates Android SDK version
make bump-ios        # Updates iOS SDK version
```

### 2. Bump Flutter Package Version

Use semantic versioning to release a new version:

```bash
make release-patch    # 0.4.4 → 0.4.5
make release-minor    # 0.4.4 → 0.5.0
make release-major    # 0.4.4 → 1.0.0
```

**Note:** Publishing uses OIDC authentication (no manual secrets required).