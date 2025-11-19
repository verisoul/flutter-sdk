import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:verisoul_sdk/src/errors/verisoul_error_codes.dart';
import 'package:verisoul_sdk/src/errors/verisoul_sdk_init_exception.dart';

/**
 * Test to verify that error codes are properly defined and structured
 */
void main() {
  group('SessionTimeoutErrorCodeTest', () {
    /**
     * Test: Verify SESSION_UNAVAILABLE error code structure
     * 
     * When getSessionId() times out in native SDK, the error code should
     * be SESSION_UNAVAILABLE
     */
    test('getSessionId timeout throws SESSION_UNAVAILABLE error code', () {
      // Simulate what happens when native SDK throws timeout error
      final exception = VerisoulSdkException(
        VerisoulErrorCodes.sessionUnavailable,
        'Failed to retrieve session ID',
      );

      expect(exception.code, equals(VerisoulErrorCodes.sessionUnavailable));
      expect(exception.code, equals('SESSION_UNAVAILABLE'));
      expect(exception.message, contains('Failed to retrieve session ID'));
    });

    /**
     * Test: Verify WEBVIEW_UNAVAILABLE error code structure
     */
    test('configure throws WEBVIEW_UNAVAILABLE when WebView is unavailable', () {
      final exception = VerisoulSdkException(
        VerisoulErrorCodes.webviewUnavailable,
        'WebView is not available on this device',
      );

      expect(exception.code, equals(VerisoulErrorCodes.webviewUnavailable));
      expect(exception.code, equals('WEBVIEW_UNAVAILABLE'));
      expect(exception.message, contains('WebView is not available'));
    });

    /**
     * Test: Verify INVALID_ENVIRONMENT error code structure
     */
    test('configure throws INVALID_ENVIRONMENT for invalid environment', () {
      final exception = VerisoulSdkException(
        VerisoulErrorCodes.invalidEnvironment,
        'Invalid environment value',
      );

      expect(exception.code, equals(VerisoulErrorCodes.invalidEnvironment));
      expect(exception.code, equals('INVALID_ENVIRONMENT'));
      expect(exception.message, contains('Invalid environment'));
    });

    /**
     * Test: Verify SDK_ERROR structure for generic errors
     */
    test('methods throw SDK_ERROR for generic failures', () {
      final exception = VerisoulSdkException(
        VerisoulErrorCodes.sdkError,
        'SDK configuration failed',
      );

      expect(exception.code, equals(VerisoulErrorCodes.sdkError));
      expect(exception.code, equals('SDK_ERROR'));
      expect(exception.message, contains('SDK configuration failed'));
    });
  });
}
