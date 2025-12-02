/// Test results data model
class TestResults {
  final int totalRounds;
  final int successCount;
  final int failureCount;
  final List<double> sessionLatencies;
  final double averageLatency;

  TestResults({
    required this.totalRounds,
    required this.successCount,
    required this.failureCount,
    required this.sessionLatencies,
    required this.averageLatency,
  });

  factory TestResults.empty() {
    return TestResults(
      totalRounds: 0,
      successCount: 0,
      failureCount: 0,
      sessionLatencies: [],
      averageLatency: 0,
    );
  }
}

