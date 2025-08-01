import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VerisoulSdk.configure(
      projectId: "<YOUR_PROJECT_ID>", environment: VerisoulEnvironment.sandbox);
  runApp(VerisoulWrapper(child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String sessionId = "";

  @override
  void initState() {
    super.initState();
  }

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
          throw e;
        }
      }
    }

    return null;
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
