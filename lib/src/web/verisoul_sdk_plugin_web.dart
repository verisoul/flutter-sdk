import 'dart:async';
import 'dart:js_interop';

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

  @override
  Future<String> getSessionId() async {
    try {
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
      throw Exception("Unable to retrieve sessionId");
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
