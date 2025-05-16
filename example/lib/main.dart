import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VerisoulSdk.configure(
      projectId: "00000000-0000-0000-0000-000000000001",
      environment: VerisoulEnvironment.prod,
      reinitialize: false);
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
                        final session = await VerisoulSdk.getSessionApi();
                        setState(() {
                          sessionId = session ?? "Invalid";
                        });
                      } catch (e) {
                        setState(() {
                          sessionId = e.toString();
                        });
                      }
                    },
                    child: Text("Get Session ID")),
                TextButton(
                    onPressed: () async {
                      try {
                        await VerisoulSdk.reinitialize();
                        final session = await VerisoulSdk.getSessionApi();
                        setState(() {
                          sessionId = session ?? "Invalid";
                        });
                      } catch (e) {
                        setState(() {
                          sessionId = e.toString();
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
