import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  VerisoulSdk.configure(
      projectId: "Project ID ", environment: VerisoulEnvironment.prod);
  runApp(const MyApp());
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GestureDetector(
            onPanDown: (event) {
              VerisoulSdk.touchEvent(
                  x: event.localPosition.dx,
                  y: event.localPosition.dy,
                  action: MotionAction.down);
            },
            onPanEnd: (event) {
              VerisoulSdk.touchEvent(
                  x: event.localPosition.dx,
                  y: event.localPosition.dy,
                  action: MotionAction.up);
            },
            onPanUpdate: (event) {
              VerisoulSdk.touchEvent(
                  x: event.localPosition.dx,
                  y: event.localPosition.dy,
                  action: MotionAction.move);
            },
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
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  "SessionID: $sessionId",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 16),
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
                    child: Text("Get Session ID"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
