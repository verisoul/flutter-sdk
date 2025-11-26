import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'test_results.dart';
import 'results_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(VerisoulWrapper(child: const MyApp()));
}

/// Map env string to VerisoulEnvironment
VerisoulEnvironment getEnvironment(String env) {
  switch (env.toLowerCase()) {
    case 'production':
    case 'prod':
      return VerisoulEnvironment.prod;
    case 'sandbox':
      return VerisoulEnvironment.sandbox;
    case 'staging':
      return VerisoulEnvironment.staging;
    case 'dev':
    default:
      return VerisoulEnvironment.dev;
  }
}

enum SDKStatus { loading, success, failed }

class ConfigError {
  final String? code;
  final String? message;
  ConfigError({this.code, this.message});
}

class TestResultState {
  final String status; // 'idle', 'running', 'passed', 'failed'
  final String expectedCode;
  final String? actualCode;
  final String? message;
  final int? durationMs;

  TestResultState({
    required this.status,
    required this.expectedCode,
    this.actualCode,
    this.message,
    this.durationMs,
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // SDK configuration state
  SDKStatus sdkStatus = SDKStatus.loading;
  ConfigError? configError;

  // Test state
  String sessionId = "";
  String testStatus = "";
  final Random _random = Random();
  bool isRunning = false;

  // Results modal state
  bool showResults = false;
  TestResults? testResults;
  String testType = '';

  // Repeat Test Config
  int repeatRounds = 10;
  int reinitMultiple = 3;
  bool parallelMode = false;

  // Chaos Test Config
  int chaosRounds = 40;

  // Network unavailable test state
  bool networkTestRunning = false;
  TestResultState? networkTestResult;

  // Test tracking
  int _successCount = 0;
  int _failureCount = 0;
  List<double> _sessionLatencies = [];

  @override
  void initState() {
    super.initState();
    _configureSDK();
  }

  Future<void> _configureSDK() async {
    setState(() {
      sdkStatus = SDKStatus.loading;
      configError = null;
    });

    try {
      final projectId = dotenv.env['PROJECT_ID'] ?? '';
      final envString = dotenv.env['ENVIRONMENT'] ?? 'prod';
      final environment = getEnvironment(envString);

      await VerisoulSdk.configure(projectId: projectId, environment: environment);
      print('Verisoul SDK configured successfully');

      // Reinitialize to clear any cached session and force new WebView creation
      try {
        print('Reinitializing SDK to verify WebView availability...');
        await VerisoulSdk.reinitialize();
        print('Getting fresh session ID...');
        final session = await VerisoulSdk.getSessionApi();
        print('Session ID obtained: ${session?.substring(0, 8)}...');
        setState(() {
          sdkStatus = SDKStatus.success;
          sessionId = session ?? '';
        });
      } on VerisoulSdkException catch (e) {
        print('SDK verification failed: code=${e.code}, message=${e.message}');
        setState(() {
          configError = ConfigError(code: e.code, message: e.message);
          sdkStatus = SDKStatus.failed;
        });
      }
    } on VerisoulSdkException catch (e) {
      print('Failed to configure Verisoul SDK: code=${e.code}, message=${e.message}');
      setState(() {
        configError = ConfigError(code: e.code, message: e.message);
        sdkStatus = SDKStatus.failed;
      });
    } catch (e) {
      print('Failed to configure Verisoul SDK: $e');
      setState(() {
        configError = ConfigError(code: 'UNKNOWN', message: e.toString());
        sdkStatus = SDKStatus.failed;
      });
    }
  }

  bool get isDisabled => sdkStatus != SDKStatus.success || isRunning;

  /// Get session with timing
  Future<(String?, double)> _getSessionWithTiming() async {
    final stopwatch = Stopwatch()..start();
    try {
      final session = await VerisoulSdk.getSessionApi();
      stopwatch.stop();
      return (session, stopwatch.elapsedMilliseconds.toDouble());
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  /// Call the authenticate API
  Future<bool> _callAuthenticate(String sessionId) async {
    try {
      final envString = dotenv.env['ENVIRONMENT'] ?? 'prod';
      final baseUrl = envString == 'staging'
          ? 'https://api.staging.verisoul.ai'
          : 'https://api.prod.verisoul.ai';
      final apiKey = dotenv.env['API_KEY'] ?? '';

      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$baseUrl/session/authenticate'));

      request.headers.set('Content-Type', 'application/json');
      request.headers.set('x-api-key', apiKey);

      final body = jsonEncode({
        'account': {'id': 'test-$sessionId'},
        'session_id': sessionId,
      });

      request.write(body);

      final response = await request.close();
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      print('Authenticate API call failed: $e');
      return false;
    }
  }

  /// Repeat test - Sequential or Parallel mode
  Future<void> _repeatTest() async {
    setState(() {
      isRunning = true;
      testStatus = parallelMode
          ? "Running repeat test (parallel)..."
          : "Running repeat test (sequential)...";
      _successCount = 0;
      _failureCount = 0;
      _sessionLatencies = [];
    });

    if (parallelMode) {
      // Fire all requests at once
      final futures = <Future<void>>[];
      for (int i = 0; i < repeatRounds; i++) {
        futures.add(_runSingleRound(i));
      }
      await Future.wait(futures);
    } else {
      // Sequential mode
      for (int i = 0; i < repeatRounds; i++) {
        await _runSingleRound(i);
      }
    }

    // Calculate average latency
    final avgLatency = _sessionLatencies.isNotEmpty
        ? _sessionLatencies.reduce((a, b) => a + b) / _sessionLatencies.length
        : 0.0;

    setState(() {
      isRunning = false;
      testStatus = "Repeat test completed. Failures: $_failureCount";
      testResults = TestResults(
        totalRounds: repeatRounds,
        successCount: _successCount,
        failureCount: _failureCount,
        sessionLatencies: List.from(_sessionLatencies),
        averageLatency: avgLatency,
      );
      testType = parallelMode ? 'Repeat Test (Parallel)' : 'Repeat Test (Sequential)';
      showResults = true;
    });
  }

  Future<void> _runSingleRound(int i) async {
    try {
      String? sid;
      double latency = 0;

      if (i > 0 && i % reinitMultiple == 0) {
        await VerisoulSdk.reinitialize();
      }

      final result = await _getSessionWithTiming();
      sid = result.$1;
      latency = result.$2;

      if (sid != null) {
        _sessionLatencies.add(latency);
        final ok = await _callAuthenticate(sid);
        print('VS-TEST [$i] sid=$sid latency=${latency}ms api=${ok ? "200" : "FAIL"}');
        if (ok) {
          _successCount++;
        } else {
          _failureCount++;
        }
      } else {
        print('VS-TEST [$i] Failed to get session ID');
        _failureCount++;
      }
    } catch (e) {
      print('VS-TEST [$i] exception -> ${e.toString()}');
      _failureCount++;
    }
  }

  /// Chaos test
  Future<void> _chaosTest() async {
    setState(() {
      isRunning = true;
      testStatus = "Running chaos test...";
      _successCount = 0;
      _failureCount = 0;
      _sessionLatencies = [];
    });

    const int concurrency = 8;
    const int minDelay = 100;
    const int maxDelay = 500;

    print('CHAOS: Launching $concurrency workers for $chaosRounds total rounds');

    final futures = <Future>[];
    for (int workerId = 0; workerId < concurrency; workerId++) {
      futures.add(_chaosWorker(workerId, chaosRounds, concurrency, minDelay, maxDelay));
    }

    await Future.wait(futures);

    // Calculate average latency
    final avgLatency = _sessionLatencies.isNotEmpty
        ? _sessionLatencies.reduce((a, b) => a + b) / _sessionLatencies.length
        : 0.0;

    setState(() {
      isRunning = false;
      testStatus = "Chaos test completed. Failures: $_failureCount";
      testResults = TestResults(
        totalRounds: chaosRounds,
        successCount: _successCount,
        failureCount: _failureCount,
        sessionLatencies: List.from(_sessionLatencies),
        averageLatency: avgLatency,
      );
      testType = 'Chaos Test';
      showResults = true;
    });

    print('CHAOS: Finished $chaosRounds rounds – $_failureCount failures');
  }

  Future<void> _chaosWorker(
      int workerId, int rounds, int concurrency, int minDelay, int maxDelay) async {
    for (int round = workerId; round < rounds; round += concurrency) {
      await _randomWork(round, minDelay, maxDelay);
    }
  }

  Future<void> _randomWork(int round, int minDelay, int maxDelay) async {
    print('CHAOS: → Round $round started');

    try {
      String? sid;
      double latency = 0;

      if (_random.nextBool()) {
        print('CHAOS: → Performing reinitialize()');
        await VerisoulSdk.reinitialize();
      }

      final result = await _getSessionWithTiming();
      sid = result.$1;
      latency = result.$2;

      if (sid != null) {
        _sessionLatencies.add(latency);
        print('CHAOS: → Got sessionId: $sid (latency: ${latency}ms)');

        // Random delay
        final delay = minDelay + _random.nextInt(maxDelay - minDelay);
        await Future.delayed(Duration(milliseconds: delay));

        final ok = await _callAuthenticate(sid);
        print(
            'CHAOS: [${round.toString().padLeft(2, '0')}] sid=$sid  api=${ok ? "200" : "FAIL"}');

        if (ok) {
          _successCount++;
        } else {
          _failureCount++;
        }
      } else {
        print('CHAOS: [${round.toString().padLeft(2, '0')}] Failed to get session ID');
        _failureCount++;
      }
    } catch (e) {
      print('CHAOS: [${round.toString().padLeft(2, '0')}] exception → ${e.toString()}');
      _failureCount++;
    }

    print('CHAOS: → Round $round done');
  }

  /// Network Unavailable Test
  Future<void> _handleNetworkUnavailableTest() async {
    setState(() {
      networkTestRunning = true;
      networkTestResult = TestResultState(
        status: 'running',
        expectedCode: VerisoulErrorCodes.sessionUnavailable,
        message: 'Test in progress... This may take up to 2 minutes.',
      );
    });

    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      print('[Network Test] Starting network unavailable test...');
      print('[Network Test] Calling reinitialize()...');
      await VerisoulSdk.reinitialize();
      print('[Network Test] Calling getSessionApi()...');
      final session = await VerisoulSdk.getSessionApi();

      // If we get here, the test failed - we expected an error
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      print('[Network Test] Unexpected success - got session: ${session?.substring(0, 8)}...');

      setState(() {
        networkTestResult = TestResultState(
          status: 'failed',
          expectedCode: VerisoulErrorCodes.sessionUnavailable,
          actualCode: 'none (success)',
          message:
              'Got session ID instead of error. Is airplane mode enabled? Session: ${session?.substring(0, 8)}...',
          durationMs: duration,
        );
        networkTestRunning = false;
      });
    } on VerisoulSdkException catch (e) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      print('[Network Test] Error received: code=${e.code}, message=${e.message}');

      final passed = e.code == VerisoulErrorCodes.sessionUnavailable;
      setState(() {
        networkTestResult = TestResultState(
          status: passed ? 'passed' : 'failed',
          expectedCode: VerisoulErrorCodes.sessionUnavailable,
          actualCode: e.code,
          message: e.message,
          durationMs: duration,
        );
        networkTestRunning = false;
      });
    } catch (e) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      print('[Network Test] Unexpected error: $e');

      setState(() {
        networkTestResult = TestResultState(
          status: 'failed',
          expectedCode: VerisoulErrorCodes.sessionUnavailable,
          actualCode: 'unknown',
          message: e.toString(),
          durationMs: duration,
        );
        networkTestRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Verisoul SDK Test Suite'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Image.asset(
                        "assets/verisoul-logo-light.png",
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SDK Status Section
                    _buildSdkStatusSection(),
                    const Divider(height: 32),

                    // Repeat Test Section
                    _buildRepeatTestSection(),
                    const Divider(height: 32),

                    // Chaos Test Section
                    _buildChaosTestSection(),
                    const Divider(height: 32),

                    // WebView Unavailable Test Section
                    _buildWebViewUnavailableTestSection(),
                    const Divider(height: 32),

                    // Network Unavailable Test Section
                    _buildNetworkUnavailableTestSection(),

                    // Web-only Set Account
                    if (kIsWeb) ...[
                      const Divider(height: 32),
                      _buildWebOnlySection(),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Results Modal
            if (showResults && testResults != null)
              Positioned.fill(
                child: ResultsView(
                  results: testResults!,
                  testType: testType,
                  onDismiss: () {
                    setState(() {
                      showResults = false;
                      testResults = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSdkStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SDK Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (sdkStatus == SDKStatus.loading)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Configuring SDK...', style: TextStyle(color: Colors.grey)),
                ],
              )
            else if (sdkStatus == SDKStatus.success)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('SDK Configured', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  if (sessionId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Session: ${sessionId.length > 16 ? '${sessionId.substring(0, 16)}...' : sessionId}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ],
              )
            else if (sdkStatus == SDKStatus.failed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('SDK Configuration Failed',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  if (configError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code: ${configError!.code ?? 'undefined'}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Message: ${configError!.message ?? 'undefined'}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 12),
            if (testStatus.isNotEmpty)
              Text(
                testStatus,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repeat Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Number of Rounds:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: '$repeatRounds'),
                          onChanged: (v) => repeatRounds = int.tryParse(v) ?? 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Reinitialize Every:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: '$reinitMultiple'),
                          onChanged: (v) => reinitMultiple = int.tryParse(v) ?? 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('rounds'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Parallel Mode (Fire All at Once)'),
                      Switch(
                        value: parallelMode,
                        onChanged: (v) => setState(() => parallelMode = v),
                      ),
                    ],
                  ),
                  Text(
                    parallelMode
                        ? '⚡ All requests fire simultaneously'
                        : '📝 Requests run sequentially',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDisabled ? null : _repeatTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('🔁 Run Repeat Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaosTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chaos Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Number of Rounds:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: '$chaosRounds'),
                          onChanged: (v) => chaosRounds = int.tryParse(v) ?? 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Runs 8 concurrent workers with random delays',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDisabled ? null : _chaosTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('🌪️ Run Chaos Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewUnavailableTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WebView Unavailable Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tests ${VerisoulErrorCodes.webviewUnavailable} error code propagation.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Test Steps:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text('1. Disable WebView on emulator:'),
                  Container(
                    margin: const EdgeInsets.only(left: 12, top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'adb shell pm disable-user --user 0 com.google.android.webview',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('2. Restart/Rebuild the app'),
                  const SizedBox(height: 4),
                  const Text('3. SDK configure() should fail with WEBVIEW_UNAVAILABLE'),
                  const SizedBox(height: 8),
                  const Text(
                    'To re-enable WebView:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 12, top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'adb shell pm enable com.google.android.webview',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Show automatic test result based on initial configure()
            if (sdkStatus == SDKStatus.failed && configError != null)
              _buildTestResultBox(
                passed: configError!.code == VerisoulErrorCodes.webviewUnavailable,
                title: configError!.code == VerisoulErrorCodes.webviewUnavailable
                    ? '✅ TEST PASSED'
                    : '❌ TEST FAILED (wrong error code)',
                expectedCode: VerisoulErrorCodes.webviewUnavailable,
                actualCode: configError!.code,
                message: configError!.message,
              ),

            if (sdkStatus == SDKStatus.success)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ WebView is Available',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'SDK configured successfully. To test WEBVIEW_UNAVAILABLE, disable WebView first and restart the app.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sdkStatus == SDKStatus.loading ? null : _configureSDK,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('🔄 Retry SDK Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkUnavailableTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Unavailable Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tests ${VerisoulErrorCodes.sessionUnavailable} error code when network is unavailable.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Test Steps:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text('1. Enable Airplane Mode on the device/emulator'),
                  const SizedBox(height: 4),
                  const Text('2. Press the "Run Network Test" button below'),
                  const SizedBox(height: 4),
                  const Text('3. Wait ~2 minutes for SDK retries to exhaust'),
                  const SizedBox(height: 4),
                  const Text('4. Should receive SESSION_UNAVAILABLE error'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: networkTestRunning ? null : _handleNetworkUnavailableTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: Text(networkTestRunning
                    ? '⏳ Test Running...'
                    : '✈️ Run Network Unavailable Test'),
              ),
            ),
            const SizedBox(height: 12),
            if (networkTestResult != null)
              _buildTestResultBox(
                passed: networkTestResult!.status == 'passed',
                isRunning: networkTestResult!.status == 'running',
                title: networkTestResult!.status == 'running'
                    ? '⏳ TEST RUNNING'
                    : networkTestResult!.status == 'passed'
                        ? '✅ TEST PASSED'
                        : '❌ TEST FAILED',
                expectedCode: networkTestResult!.expectedCode,
                actualCode: networkTestResult!.actualCode,
                message: networkTestResult!.message,
                durationMs: networkTestResult!.durationMs,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultBox({
    required bool passed,
    bool isRunning = false,
    required String title,
    required String expectedCode,
    String? actualCode,
    String? message,
    int? durationMs,
  }) {
    Color bgColor;
    Color borderColor;

    if (isRunning) {
      bgColor = Colors.yellow.shade50;
      borderColor = Colors.orange;
    } else if (passed) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green;
    } else {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Expected: $expectedCode',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          Text(
            'Actual: ${actualCode ?? 'pending...'}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          if (durationMs != null)
            Text(
              'Duration: ${(durationMs / 1000).toStringAsFixed(1)}s',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebOnlySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Web Only',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await VerisoulSdk.setAccountData(
                    id: "example-id",
                    email: "example@example.com",
                    metadata: {"paid": true},
                  );
                },
                child: const Text('Set Account Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
