import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:verisoul_sdk/src/generated/verisoul.api.g.dart';
import 'package:verisoul_sdk/src/web/web_utils.dart';
import 'package:verisoul_sdk/src/web/verisoul_js.dart';

class VerisoulSdkPlugin extends VerisoulApiHostApi {
  static void registerWith(Registrar registrar) {
    // Register the web implementation
  }

  @override
  Future<void> configure(int enviromentVariable, String projectId) async {}

  /// ✅ Check if the Verisoul SDK is loaded
  bool isVerisoulLoaded() {
    return globalContext.has("Verisoul");
  }

  /// Waits until Verisoul SDK is available (up to 10 seconds)
  Future<void> waitForVerisoul({int timeoutMs = 10000}) async {
    final start = DateTime.now();
    while (!isVerisoulLoaded()) {
      if (DateTime.now().difference(start).inMilliseconds > timeoutMs) {
        throw Exception("Verisoul SDK failed to load JS SDK");
      }
      await Future.delayed(Duration(milliseconds: 2000));
    }
  }

  @override
  Future<String> getSessionId() async {
    try {
      await waitForVerisoul();
      final jsPromise = VerisoulJS.session();
      if (jsPromise == null) return '';

      // Convert JavaScript Promise to Future
      final resolved = await jsPromise.toDart;

      // Extract session_id from JSObject
      final sessionId = resolved.getStringProperty('session_id');
      if (sessionId == null) {
        throw Exception("Unable to retrieve sessionId");
      }
      return sessionId;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> onTouchEvent(double x, double y, int motionType) async {}

  @override
  Future<void> setAccountData(Map<String, Object?> account) async {
    try {
      VerisoulJS.account(mapToJSObject(account));
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Future<void> reinitialize() async {
    try {
      VerisoulJS.reinitialize();
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
    }
  }
}
