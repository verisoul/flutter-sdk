import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:verisoul_sdk/verisoul_sdk.dart';

class TestResults {
  final int successCount;
  final int failureCount;
  final List<double> sessionLatencies;
  final double averageLatency;
  final int totalRounds;

  TestResults({
    required this.successCount,
    required this.failureCount,
    required this.sessionLatencies,
    required this.averageLatency,
    required this.totalRounds,
  });
}

class ResultsTracker {
  int _successCount = 0;
  int _failureCount = 0;
  final List<double> _sessionLatencies = [];

  void recordSuccess(double latency) {
    _successCount += 1;
    _sessionLatencies.add(latency);
  }

  void recordFailure(double latency) {
    _failureCount += 1;
    _sessionLatencies.add(latency);
  }

  TestResults getResults() {
    final averageLatency = _sessionLatencies.isNotEmpty
        ? _sessionLatencies.reduce((a, b) => a + b) / _sessionLatencies.length
        : 0.0;

    return TestResults(
      successCount: _successCount,
      failureCount: _failureCount,
      sessionLatencies: List.from(_sessionLatencies),
      averageLatency: averageLatency,
      totalRounds: _successCount + _failureCount,
    );
  }
}

// Get current timestamp in milliseconds
int _now() => DateTime.now().millisecondsSinceEpoch;

// Get session ID
Future<String> _getSessionId() async {
  final sessionId = await VerisoulSdk.getSessionApi();
  return sessionId ?? '';
}

// Reinitialize and get session ID
Future<String> _reinitAndGet() async {
  await VerisoulSdk.reinitialize();
  return await _getSessionId();
}

// Call authenticate API
Future<bool> _callAuthenticate(String sid) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.sandbox.verisoul.ai/session/authenticate'),
      headers: {
        'x-api-key': '<API_KEY>',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'account': {'id': 'test-$sid'},
        'session_id': sid,
      }),
    );
    return response.statusCode == 200;
  } catch (error) {
    return false; // network / TLS failure counts as "FAIL"
  }
}

// Sleep utility
Future<void> _sleep(int ms) async {
  await Future.delayed(Duration(milliseconds: ms));
}

// Run a single repeat test round
Future<void> _runRepeatRound(
  int round,
  int reinitMultiple,
  ResultsTracker tracker,
) async {
  final startTime = _now();

  try {
    final shouldReinit =
        reinitMultiple > 0 && round > 0 && round % reinitMultiple == 0;
    final sid = shouldReinit ? await _reinitAndGet() : await _getSessionId();

    final sessionLatency = (_now() - startTime).toDouble();

    final ok = await _callAuthenticate(sid);
    print(
      '[$round] sid=$sid  api=${ok ? '200' : 'FAIL'}  latency=${sessionLatency.toStringAsFixed(2)}ms',
    );

    if (ok) {
      tracker.recordSuccess(sessionLatency);
    } else {
      tracker.recordFailure(sessionLatency);
    }
  } catch (error) {
    final sessionLatency = (_now() - startTime).toDouble();
    print(
      '[$round] exception → $error  latency=${sessionLatency.toStringAsFixed(2)}ms',
    );
    tracker.recordFailure(sessionLatency);
  }
}

/// Run repeat test
/// [times] Number of rounds to run
/// [reinitMultiple] Reinitialize every N rounds
/// [parallel] If true, run all requests in parallel; if false, run sequentially
Future<TestResults> runRepeatTest(
  int times, {
  int reinitMultiple = 3,
  bool parallel = false,
}) async {
  final tracker = ResultsTracker();

  if (parallel) {
    // Fire-and-forget mode: launch all requests without awaiting
    final futures = <Future<void>>[];
    for (int i = 0; i < times; i++) {
      futures.add(_runRepeatRound(i, reinitMultiple, tracker));
    }
    await Future.wait(futures);
  } else {
    // Sequential mode: await each request before starting the next
    for (int i = 0; i < times; i++) {
      await _runRepeatRound(i, reinitMultiple, tracker);
    }
  }

  return tracker.getResults();
}

// Run a single chaos test round
Future<void> _runChaosRound(
  int round,
  List<int> delayRange,
  ResultsTracker tracker,
) async {
  final startTime = _now();

  try {
    final sid = (DateTime.now().millisecond % 2 == 0)
        ? await _reinitAndGet()
        : await _getSessionId();

    final sessionLatency = (_now() - startTime).toDouble();

    // Add jitter to increase overlap
    final sleepMS = delayRange[0] +
        (DateTime.now().microsecond % (delayRange[1] - delayRange[0] + 1));
    await _sleep(sleepMS);

    final ok = await _callAuthenticate(sid);
    print(
      '[${round.toString().padLeft(2, '0')}] sid=$sid  api=${ok ? '200' : 'FAIL'}  latency=${sessionLatency.toStringAsFixed(2)}ms',
    );

    if (ok) {
      tracker.recordSuccess(sessionLatency);
    } else {
      tracker.recordFailure(sessionLatency);
    }
  } catch (error) {
    final sessionLatency = (_now() - startTime).toDouble();
    print(
      '[${round.toString().padLeft(2, '0')}] exception → $error  latency=${sessionLatency.toStringAsFixed(2)}ms',
    );
    tracker.recordFailure(sessionLatency);
  }
}

/// Run chaos test with concurrent workers
/// [rounds] Total number of rounds
/// [concurrency] Number of concurrent workers
/// [randomDelay] Delay range in milliseconds [min, max]
Future<TestResults> runChaosTest(
  int rounds, {
  int concurrency = 8,
  List<int> randomDelay = const [200, 900],
}) async {
  final tracker = ResultsTracker();

  // Launch N workers; each worker handles every N-th round
  final workers = <Future<void>>[];
  for (int workerIdx = 0; workerIdx < concurrency; workerIdx++) {
    final worker = Future(() async {
      int round = workerIdx;
      while (round < rounds) {
        await _runChaosRound(round, randomDelay, tracker);
        round += concurrency;
      }
    });
    workers.add(worker);
  }

  await Future.wait(workers);

  final results = tracker.getResults();
  print(
    'Finished $rounds rounds – ${results.failureCount} failures, avg latency: ${results.averageLatency.toStringAsFixed(2)}ms',
  );

  return results;
}

