import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:verisoul_sdk/src/models/verisoul_account.dart';
import 'package:verisoul_sdk/src/web/verisoul_sdk_plugin_web.dart'
    if (dart.library.io) 'package:verisoul_sdk/src/verisoul_sdk_plugin.dart';

enum VerisoulEnvironment { dev, prod, sandbox, staging }

/// These actions are used to handle gesture events in a pan responder.
enum MotionAction {
  /// Represents the end of a gesture.
  up,

  /// Represents the start of a gesture.
  down,

  /// Represents a change during a gesture.
  move,
}

class VerisoulSdk {
  static final _host = VerisoulSdkPlugin();

  /// Retrieves the current session's replay link.
  static Future<String?> getSessionApi() => _host.getSessionId();

  /// Configures the SDK with the provided environment and project ID.
  static Future<void> configure({
    VerisoulEnvironment environment = VerisoulEnvironment.dev,
    required String projectId,
    bool reinitialize = false,
  }) =>
      _host.configure(environment.index, projectId, reinitialize);

  /// Reports touch events.
  static Future<void> touchEvent({
    required double x,
    required double y,
    required MotionAction action,
  }) =>
      _host.onTouchEvent(x, y, action.index);

  /// Sets account data (Web-only).
  static Future<void> setAccountData(
          {required String id,
          String? email,
          Map<String, dynamic>? metadata}) =>
      kIsWeb
          ? _host.setAccountData(
              VerisoulAccount(id: id, email: email, metadata: metadata).toMap())
          : Future<void>.value();

  /// Reinitializes the SDK.
  static Future<void> reinitialize() => _host.reinitialize();
}
