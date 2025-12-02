/// Custom exception for Verisoul SDK errors.
/// Provides standardized error codes for consistent error handling.
///
/// [code] - The error code from [VerisoulErrorCodes]
/// [message] - Human readable error message
/// [cause] - The underlying cause of the exception
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
