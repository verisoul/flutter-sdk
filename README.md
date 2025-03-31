<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="resources/verisoul-logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="resources/verisoul-logo-light.svg">
  <img src="resources/verisoul-logo-light.svg" alt="Verisoul logo" width="312px" style="visibility:visible;max-width:100%;">
</picture>
</p>

# verisoul-Flutter

## Overview

The purpose of this app is to demonstrate Verisoul's Android SDK integration.

_To run the app a Verisoul Project ID is required._ Schedule a call [here](https://meetings.hubspot.com/henry-legard) to
get started.

<!-- <img src="resources/verisoul.gif" width="128"/> -->

## Getting Started

### 1. Add Dependency

```yaml
dependencies:
   flutter:
      sdk: flutter
   #  ...
   
   verisoul_sdk: 0.1.0
```

### 2. Update the Android minimum `minSdk` to **24** in `android/app/build.gradle`
```groovy
 defaultConfig {
    minSdk = 24
    //...
}
```

If an exception occurs during the build stating that the `ai.verisoul:android` package cannot be downloaded, add the
   following Maven repository inside your `android/build.gradle` file:

```groovy
allprojects {
    repositories {
    // ...

     maven { url = uri("https://us-central1-maven.pkg.dev/verisoul/android") }

    }
 }
```
### 3. Web support 
Add the Verisoul script to your `web/index.html`:

```html
<script async src="https://js.verisoul.ai/{env}/bundle.js" verisoul-project-id="{project_id}"></script>
```

#### Replace the following parameters:

* **{env}** : Use either `prod` or `sandbox`
* **{project_id**} : Your project ID, which must match the environment


#### Content Security Policy (CSP)
If your application has a Content Security Policy, update it to include the following Verisoul domains:


```html
<meta http-equiv="Content-Security-Policy" content="script-src 'self' https://js.verisoul.ai; worker-src 'self' blob: data:;connect-src 'self' https://*.verisoul.ai wss://*.verisoul.ai;">
```


## Usage

### 1. Initialization

```dart
import 'package:verisoul_sdk/verisoul.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();
   VerisoulSdk.configure(projectId: "Project ID ", environment: VerisoulEnvironment.prod);
   runApp(const MyApp());
}
```

When this is called Verisoul library will be initialized, initial data together with **session ID** will be gathered and
uploaded to Verisoul backend.

### 2. Get Session ID

Once the minimum amount of data is gathered the session ID becomes available.
The session ID is needed in order to request a risk assessment from Verisoul's API. Note that session IDs are short
lived and will expire after 24 hours. The application can obtain session ID by providing the callback as shown below:

```dart
final session = await VerisoulSdk.getSessionApi();
```

### 3. Provide Touch Events
Wrap our App with  `VerisoulWrapper`
```dart
runApp(VerisoulWrapper(child: const MyApp()));
```
### 4. Reinitialize (Web-only)

Calling `VerisoulSdk.reinitialize()` generates a new `session_id`, which ensures that if a user logs out of one account and into a different account, Verisoul will be able to delineate each account’s data cleanly.
```dart
await VerisoulSdk.reinitialize();
```
### 5.SetAccountData (Web-only)
The `setAccountData()` function provides a simplified way to send user account information to Verisoul directly from the client side. While easy to integrate, this method has important limitations:

* **Offline analysis only**: Data sent via account() is only visible in the Verisoul dashboard
* **No real-time decisions**: Unlike the server-side API, this method doesn’t allow your application to receive and act on Verisoul’s risk scores in real-time 
* **Limited use case**: Designed specifically for initial pilots and evaluation purposes
```dart
    await VerisoulSdk.setAccountData(
      id: "example-id",
      email: "example@example.com",
      metadata: {"paid": true});
```

## Android

### 1. Provide Touch Events (Android only)

In order to gather touch events and compare them to device accelerometer sensor data, the app will need to provide touch
events to Verisoul. you need to Edit th `MainActivity`, to override `dispatchTouchEvent` function and pass the data to
Verisoul like shown below.

```kotlin
import ai.verisoul.sdk.Verisoul
import android.view.MotionEvent


class MainActivity: FlutterActivity(){
   override fun onTouchEvent(event: MotionEvent?): Boolean {
      Verisoul.onTouchEvent(event)
      return super.onTouchEvent(event)
   }
}

```

## iOS

### Capabilities

To fully utilize VerisoulSDK, you must add the `App Attest` capability to your project. This capability allows the SDK
to perform necessary checks and validations to ensure the integrity and security of your application.

Update your app’s entitlements file:

```
<key>com.apple.developer.devicecheck.appattest-environment</key>
<string>production/development (depending on your needs)</string>
```

## Update the privacy manifest file

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
   PrivacyInfo.xcprivacy
   test

   Created by Raine Scott on 1/30/25.
   Copyright (c) 2025 ___ORGANIZATIONNAME___.
   All rights reserved.
-->
<plist version="1.0">
  <dict>
    <!-- Privacy manifest file for Verisoul Fraud Prevention SDK for iOS -->
    <key>NSPrivacyTracking</key>
    <false/>

    <!-- Privacy manifest file for Verisoul Fraud Prevention SDK for iOS -->
    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <!-- Privacy manifest file for Verisoul Fraud Prevention SDK for iOS -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
      <dict>
        <!-- The value provided by Apple for 'Device ID' data type -->
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeDeviceID</string>

        <!-- Verisoul Fraud Prevention SDK does not link the 'Device ID' with user's identity -->
        <key>NSPrivacyCollectedDataTypeLinked</key>
        <false/>

        <!-- Verisoul Fraud Prevention SDK does not use 'Device ID' for tracking -->
        <key>NSPrivacyCollectedDataTypeTracking</key>
        <false/>

        <!-- Verisoul Fraud Prevention SDK uses 'Device ID' for App Functionality
             (prevent fraud and implement security measures) -->
        <key>NSPrivacyCollectedDataTypePurposes</key>
        <array>
          <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        </array>
      </dict>
    </array>

    <!-- Privacy manifest file for Verisoul Fraud Prevention SDK for iOS -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
      <dict>
        <!-- The value provided by Apple for 'System boot time APIs' -->
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategorySystemBootTime</string>

        <!-- Verisoul Fraud Prevention SDK uses 'System boot time APIs' to measure the amount of
             time that has elapsed between events that occurred within the SDK -->
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
          <string>35F9.1</string>
        </array>
      </dict>
    </array>
  </dict>
</plist>

```

## Questions and Feedback

Comprehensive documentation about Verisoul's Android SDK and API can be found
at [docs.verisoul.ai](https://docs.verisoul.ai/). Additionally, reach out to Verisoul
at [help@verisoul.ai](mailto:help@verisoul.ai) for any questions or feedback.



