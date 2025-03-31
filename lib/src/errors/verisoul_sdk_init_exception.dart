class VerisoulSdkException implements Exception {
  final String message;

  VerisoulSdkException([this.message = "Verisoul SDK failed to load JS SDK"]);

  @override
  String toString() => "VerisoulSdkException: $message";
}
