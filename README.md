<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="resources/verisoul-logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="resources/verisoul-logo-light.svg">
  <img src="resources/verisoul-logo-light.svg" alt="Verisoul logo" width="312px" style="visibility:visible;max-width:100%;">
</picture>
</p>

# Flutter SDK

Verisoul provides a Flutter SDK that allows you to implement fraud prevention in your cross-platform mobile applications. This guide covers the installation, configuration, and usage of the Verisoul Flutter SDK.

_To run the app a Verisoul Project ID is required._ Schedule a call [here](https://meetings.hubspot.com/henry-legard) to get started.

## Requirements

- Flutter SDK 3.0 or higher
- Dart 2.17 or higher
- iOS 14.0 or higher
- Android API level 24 (Android 7.0) or higher
- For Web: Modern browsers with JavaScript enabled

## Installation

### Add Dependency

```yaml
dependencies:
  flutter:
    sdk: flutter
  #  ...

  verisoul_sdk: 0.4.4
```

### Android Configuration

#### 1. Update Minimum SDK Version

Update the Android minimum `minSdk` to **24** in `android/app/build.gradle`:

```groovy
 defaultConfig {
    minSdk = 24
    //...
}
```

#### 2. Add Maven Repository

If an exception occurs during the build stating that the `ai.verisoul:android` package cannot be downloaded, add the following Maven repository inside your `android/build.gradle` file:

```groovy
allprojects {
    repositories {
    // ...

     maven { url = uri("https://us-central1-maven.pkg.dev/verisoul/android") }

    }
 }
```

### iOS Configuration

For iOS-specific configuration including Device Check and App Attest setup, please refer to the [iOS SDK Documentation](https://docs.verisoul.ai/integration/frontend/ios#ios-device-check).

## Usage

### Initialize the SDK

Call `configure()` when your application starts, before running your app:

```dart
import 'package:verisoul_sdk/verisoul.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();
   VerisoulSdk.configure(projectId: "Project ID ", environment: VerisoulEnvironment.prod);
   runApp(const MyApp());
}
```

The `configure()` method initializes the Verisoul SDK with your project credentials. This method must be called once when your application starts.

**Parameters:**

- `projectId` (String): Your unique Verisoul project identifier
- `environment` (VerisoulEnvironment): The environment to use - `VerisoulEnvironment.prod` for production or `VerisoulEnvironment.sandbox` for testing

### Get Session ID

The `getSessionApi()` method returns the current session identifier after the SDK has collected sufficient device data. This session ID is required to request a risk assessment from Verisoul's API.

**Important Notes:**

- Session IDs are short-lived and expire after 24 hours
- The session ID becomes available once minimum data collection is complete (typically within seconds)
- You should send this session ID to your backend, which can then call Verisoul's API to get a risk assessment

**Example:**

```dart
final session = await VerisoulSdk.getSessionApi();
```

### Reinitialize Session

The `reinitialize()` method generates a fresh session ID and resets the SDK's data collection. This is essential for maintaining data integrity when user context changes.

**Example:**

```dart
await VerisoulSdk.reinitialize();
```

### Provide Touch Events

Wrap your App with `VerisoulWrapper` to automatically capture touch events:

```dart
runApp(VerisoulWrapper(child: const MyApp()));
```

## Example

For a complete working example, see the [example folder](https://github.com/verisoul/flutter-sdk/tree/main/example) in this repository.

## Web Support

### Add Verisoul Script

Add the Verisoul script to your `web/index.html`:

```html
<script
  async
  src="https://js.verisoul.ai/{env}/bundle.js"
  verisoul-project-id="{project_id}"
></script>
```

**Replace the following parameters:**

- **{env}**: Use either `prod` or `sandbox`
- **{project_id}**: Your project ID, which must match the environment

### Content Security Policy (CSP)

If your application has a Content Security Policy, update it to include the following Verisoul domains:

```html
<meta
  http-equiv="Content-Security-Policy"
  content="script-src 'self' https://js.verisoul.ai; worker-src 'self' blob: data:;connect-src 'self' https://*.verisoul.ai wss://*.verisoul.ai;"
/>
```

### Set Account Data (Web Only)

The `setAccountData()` function provides a simplified way to send user account information to Verisoul directly from the client side. While easy to integrate, this method has important limitations:

- **Offline analysis only**: Data sent via account() is only visible in the Verisoul dashboard
- **No real-time decisions**: Unlike the server-side API, this method doesn't allow your application to receive and act on Verisoul's risk scores in real-time
- **Limited use case**: Designed specifically for initial pilots and evaluation purposes

```dart
await VerisoulSdk.setAccountData(
  id: "example-id",
  email: "example@example.com",
  metadata: {"paid": true}
);
```

## Additional Resources

- [Verisoul Documentation](https://docs.verisoul.ai/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Verisoul Flutter SDK on Pub.dev](https://pub.dev/packages/verisoul_sdk)
- For questions or feedback, reach out at [help@verisoul.ai](mailto:help@verisoul.ai)
