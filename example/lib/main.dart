import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VerisoulSdk.configure(
      projectId: "00000000-0000-0000-0000-000000000001",
      environment: VerisoulEnvironment.prod);
  runApp(VerisoulWrapper(child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String sessionId = "";
  String testStatus = "";
  int failureCount = 0;
  final Random _random = Random();

  /*
  * Optional retry mechanism for getSessionApi()
  * There are already retries implemented in the SDK but this is an optional fallback function
  * It is recommended to treat the user as highly suspect if it fails to get a session even after 3 retries 
  */
  Future<String?> _getSessionWithRetry({bool withReinitialize = false}) async {
    const int maxRetries = 2;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (withReinitialize && attempt == 0) {
          await VerisoulSdk.reinitialize();
        }
        final session = await VerisoulSdk.getSessionApi();
        return session;
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
      }
    }

    return null;
  }

  /*
  * Call the authenticate API similar to Android implementation
  */
  Future<bool> _callAuthenticate(String sessionId) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
          Uri.parse('https://api.prod.verisoul.ai/session/authenticate'));

      request.headers.set('Content-Type', 'application/json');
      request.headers
          .set('x-api-key', 'KxEv9FlAmC6h6L8uJxctYaAt4IjWoebAarqthqV5');

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

  /*
  * Repeat test similar to Android implementation
  */
  Future<void> _repeatTest() async {
    setState(() {
      testStatus = "Running repeat test...";
      failureCount = 0;
    });

    for (int i = 0; i < 4; i++) {
      try {
        String? sid;
        if (i % 3 == 0) {
          await VerisoulSdk.reinitialize();
          sid = await _getSessionWithRetry();
        } else {
          sid = await _getSessionWithRetry();
        }

        if (sid != null) {
          final ok = await _callAuthenticate(sid);
          print('VS-TEST [$i] sid=$sid  api=${ok ? "200" : "FAIL"}');
          if (!ok) failureCount++;
        } else {
          print('VS-TEST [$i] Failed to get session ID');
          failureCount++;
        }
      } catch (e) {
        print('VS-TEST [$i] exception -> ${e.toString()}');
        failureCount++;
      }
    }

    setState(() {
      testStatus = "Repeat test completed. Failures: $failureCount";
    });
  }

  /*
  * Chaos test similar to Android implementation
  */
  Future<void> _chaosTest() async {
    setState(() {
      testStatus = "Running chaos test...";
      failureCount = 0;
    });

    const int rounds = 40;
    const int concurrency = 8;
    const int minDelay = 2000;
    const int maxDelay = 5000;

    print('CHAOS: Launching $concurrency workers for $rounds total rounds');

    final futures = <Future>[];

    for (int workerId = 0; workerId < concurrency; workerId++) {
      futures
          .add(_chaosWorker(workerId, rounds, concurrency, minDelay, maxDelay));
    }

    await Future.wait(futures);

    setState(() {
      testStatus = "Chaos test completed. Failures: $failureCount";
    });

    print('CHAOS: Finished $rounds rounds – $failureCount failures');
  }

  Future<void> _chaosWorker(int workerId, int rounds, int concurrency,
      int minDelay, int maxDelay) async {
    for (int round = workerId; round < rounds; round += concurrency) {
      await _randomWork(round, minDelay, maxDelay);
    }
  }

  Future<void> _randomWork(int round, int minDelay, int maxDelay) async {
    print('CHAOS: → Round $round started');

    try {
      String? sid;

      if (_random.nextBool()) {
        print('CHAOS: → Performing reinitialize()');
        await VerisoulSdk.reinitialize();
        sid = await _getSessionWithRetry();
      } else {
        sid = await _getSessionWithRetry();
      }

      if (sid != null) {
        print('CHAOS: → Got sessionId: $sid');

        // Random delay
        final delay = minDelay + _random.nextInt(maxDelay - minDelay);
        await Future.delayed(Duration(milliseconds: delay));

        final ok = await _callAuthenticate(sid);
        print(
            'CHAOS: [${round.toString().padLeft(2, '0')}] sid=$sid  api=${ok ? "200" : "FAIL"}');

        if (!ok) {
          setState(() {
            failureCount++;
          });
        }
      } else {
        print(
            'CHAOS: [${round.toString().padLeft(2, '0')}] Failed to get session ID');
        setState(() {
          failureCount++;
        });
      }
    } catch (e) {
      print(
          'CHAOS: [${round.toString().padLeft(2, '0')}] exception → ${e.toString()}');
      setState(() {
        failureCount++;
      });
    }

    print('CHAOS: → Round $round done');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    "assets/verisoul-logo-light.png",
                    height: 80,
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  "Flutter Sample App",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  "SessionID: $sessionId",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF000000), fontSize: 16),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Test Status: $testStatus",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
                SizedBox(
                  height: 20,
                ),
                TextButton(
                    onPressed: () async {
                      try {
                        final session = await _getSessionWithRetry();
                        setState(() {
                          sessionId = session ?? "Invalid";
                        });
                      } catch (e) {
                        setState(() {
                          sessionId = "Verisoul failed to get session";
                        });
                      }
                    },
                    child: Text("Get Session ID")),
                TextButton(
                    onPressed: () async {
                      try {
                        final session =
                            await _getSessionWithRetry(withReinitialize: true);
                        setState(() {
                          sessionId = session ?? "Invalid";
                        });
                      } catch (e) {
                        setState(() {
                          sessionId = "Verisoul failed to get session";
                        });
                      }
                    },
                    child: Text("reinitialize")),
                SizedBox(height: 10),
                TextButton(onPressed: _repeatTest, child: Text("Repeat Test")),
                TextButton(onPressed: _chaosTest, child: Text("Chaos Test")),
                if (kIsWeb)
                  TextButton(
                      onPressed: () async {
                        await VerisoulSdk.setAccountData(
                            id: "example-id",
                            email: "example@example.com",
                            metadata: {"paid": true});
                      },
                      child: Text("Set Account")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
