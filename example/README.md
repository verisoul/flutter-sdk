# Verisoul Flutter Sample App

This example app demonstrates how to integrate the Verisoul SDK into a Flutter application for fraud detection and account security.

## Requirements

- Flutter SDK 3.0 or higher
- Dart 2.17 or higher
- **iOS**: Xcode and CocoaPods on macOS
- **Android**: Android Studio and Android SDK
- Code editor (VS Code, Android Studio, or IntelliJ IDEA)

> **Note**: Make sure you have completed the [Flutter environment setup](https://docs.flutter.dev/get-started/install) guide before proceeding.

## Configure

Before running the sample app, you need to configure it with your Verisoul credentials.

1. Open `lib/main.dart` in your text editor

2. Locate the Verisoul configuration section and add your credentials:

```dart
VerisoulSdk.configure(
  projectId: "YOUR_PROJECT_ID", // Replace with your actual project ID
  environment: VerisoulEnvironment.sandbox // Change to .prod for production
);
```

3. If you don't have a Verisoul Project ID, schedule a call [here](https://meetings.hubspot.com/henry-legard) to get started.

## Get Started

### Step 1: Install Dependencies

From the `example` directory, install the required dependencies:

```sh
flutter pub get
```

### Step 2: Run the App

Choose your target platform below:

#### For Android

1. Make sure you have an Android emulator running or a physical device connected

2. From the `example` directory, run:

```sh
flutter run
```

If you have multiple devices connected, specify the device:

```sh
flutter devices  # List available devices
flutter run -d <device_id>
```

If everything is set up correctly, you should see the app running on your Android device/emulator.

#### For iOS

1. **First time setup only**: Install CocoaPods dependencies:

```sh
cd ios
pod install
cd ..
```

2. From the `example` directory, run:

```sh
flutter run
```

If you have multiple devices/simulators, specify the target:

```sh
flutter devices  # List available devices
flutter run -d <device_id>
```

The app will launch in the iOS Simulator. To run on a physical device, make sure your device is connected and trusted, then select it from the devices list.

> **Note:** You only need to run `pod install` on first clone or after updating native dependencies.

#### For Web

To run the web version:

```sh
flutter run -d chrome
```

Or for other browsers:

```sh
flutter run -d web-server
```

## Troubleshooting

### Android Build Issues

If you encounter issues with the Android build:

- Ensure `minSdk` is set to 24 in `android/app/build.gradle`
- Check that the Maven repository is configured in `android/build.gradle`
- Try cleaning the build: `flutter clean && flutter pub get`
- Check that your Android SDK is up to date

### iOS Build Issues

If you encounter issues with the iOS build:

- Make sure CocoaPods is installed: `sudo gem install cocoapods`
- Try reinstalling pods: `cd ios && pod deinstall && pod install && cd ..`
- Clean the build: `flutter clean && flutter pub get`
- If you see signing issues, open `ios/Runner.xcworkspace` in Xcode and configure your development team

### General Flutter Issues

If Flutter won't build or you see dependency issues:

```sh
# Clean and reinstall
flutter clean
flutter pub get
```

For more detailed logs:

```sh
flutter run --verbose
```

## Learn More

- [Verisoul Documentation](https://docs.verisoul.ai/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Verisoul Flutter SDK on Pub.dev](https://pub.dev/packages/verisoul_sdk)
