/// Standard error codes used by the Verisoul SDK.
/// These codes provide consistent error handling across platforms.
class VerisoulErrorCodes {
  /// WebView is not available on the device (missing, disabled, or corrupted)
  static const String webviewUnavailable = 'WEBVIEW_UNAVAILABLE';

  /// Session is not available or could not be retrieved
  static const String sessionUnavailable = 'SESSION_UNAVAILABLE';

  /// SDK configuration failed
  static const String sdkError = 'SDK_ERROR';

  /// Invalid environment parameter
  static const String invalidEnvironment = 'INVALID_ENVIRONMENT';
}
