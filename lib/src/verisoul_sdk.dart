import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:verisoul_sdk/src/errors/verisoul_error_codes.dart';
import 'package:verisoul_sdk/src/errors/verisoul_sdk_init_exception.dart';
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

  /// Retrieves the current session ID for the active SDK session.
  ///
  /// Returns a [Future] that resolves to the session ID as a [String].
  ///
  /// Throws [VerisoulSdkException] if the session ID cannot be retrieved.
  static Future<String?> getSessionApi() async {
    try {
      return await _host.getSessionId();
    } on PlatformException catch (e) {
      throw VerisoulSdkException(
        e.code,
        e.message ?? 'Failed to retrieve session ID',
        cause: e,
      );
    }
  }

  /// Initializes and configures the Verisoul SDK.
  ///
  /// This method should be called before using other features of the SDK.
  ///
  /// [environment] specifies the environment to use (e.g., development, production).
  /// Defaults to [VerisoulEnvironment.dev].
  ///
  /// [projectId] is a required string that uniquely identifies the project.
  ///
  /// Throws [VerisoulSdkException] if configuration fails
  static Future<void> configure({
    VerisoulEnvironment environment = VerisoulEnvironment.dev,
    required String projectId,
  }) async {
    try {
      await _host.configure(environment.index, projectId);
    } on PlatformException catch (e) {
      throw VerisoulSdkException(
        e.code,
        e.message ?? 'Failed to configure Verisoul SDK',
        cause: e,
      );
    }
  }

  /// Sends a touch event to the SDK.
  ///
  /// This is used for gesture tracking or behavior analysis.
  ///
  /// [x] and [y] specify the position of the touch event.
  /// [action] defines the type of motion (e.g., down, move, up).
  static Future<void> touchEvent({
    required double x,
    required double y,
    required MotionAction action,
  }) =>
      _host.onTouchEvent(x, y, action.index);

  /// Sets the current user's account data (Web-only).
  ///
  /// This includes identifiers and optional metadata to help link the session
  /// to a specific user.
  ///
  /// [id] is a required user identifier.
  /// [email] is an optional user email address.
  /// [metadata] is an optional map of key-value pairs with additional info.
  ///
  /// Has no effect on platforms other than Web.
  static Future<void> setAccountData({
    required String id,
    String? email,
    Map<String, dynamic>? metadata,
  }) =>
      kIsWeb
          ? _host.setAccountData(
              VerisoulAccount(id: id, email: email, metadata: metadata).toMap())
          : Future<void>.value();

  /// Reinitializes the Verisoul SDK.
  ///
  /// Useful if configuration has changed or a fresh session is required.
  static Future<void> reinitialize() => _host.reinitialize();
}
