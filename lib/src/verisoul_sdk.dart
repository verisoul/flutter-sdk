import 'package:verisoul_sdk/src/generated/verisoul.api.g.dart';

enum VerisoulEnvironment { dev, prod, sandbox, staging }

///These actions are used to handle gesture events in a pan responder.
enum MotionAction {
  ///Represents the end of a gesture. The motion contains the final release location
  /// and any intermediate points since the last down or move event.
  /// This is the point where the gesture is released.
  up,

  ///Represents the start of a gesture. The motion contains the initial starting location.
  /// This is the point where the gesture is granted, and initial coordinates are captured.
  down,

  ///Represents a change during a gesture (between up and down).
  /// The motion contains the most recent point and any intermediate points
  /// since the last down or move event. This is the point where the gesture is moving.
  move
}

class VerisoulSdk {
  static final _host = VerisoulApiHostApi();

  /// Retrieves current session's replay link.
  static Future<String?> getSessionApi() {
    return _host.getSessionId();
  }

  /// Configures the SDK with the provided environment, project ID, and bundle identifier.
  /// Initializes networking, device check, and device attestation components.
  /// [environment] The environment to configure the SDK with (e.g., dev, staging, prod).
  /// [projectId] The project ID to be used in networking requests.
  static Future<void> configure(
      {VerisoulEnvironment environment = VerisoulEnvironment.dev,
      required String projectId}) {
    return _host.configure(environment.index, projectId);
  }

  ///report actions are used to handle gesture events in a pan responder.
  /// [x] the location of touch event in X axis
  /// [y] the location of touch event in Y axis
  /// [action] touch up , down or moving
  static Future<void> touchEvent(
      {required double x, required double y, required MotionAction action}) {
    return _host.onTouchEvent(x, y, action.index);
  }
}
