/**
 * Custom exception for Verisoul SDK errors
 * Provides standardized error codes for consistent error handling
 *
 * @param code - The error code [VerisoulErrorCodes]
 * @param message - Human readable error message
 * @param cause - The underlying cause of the exception
 */
class VerisoulSdkException implements Exception {
  
  final String code;
  
  final String message;
  
  final dynamic cause;

  VerisoulSdkException(
    this.code,
    this.message, {
    this.cause,
  });

  @override
  String toString() => "VerisoulSdkException(code='$code', message='$message')";
}
