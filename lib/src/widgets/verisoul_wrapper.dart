import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';

/// A widget that wraps a child to report user touch interactions to Verisoul.
///
/// This widget is useful for tracking user gestures in Android applications
/// and forwarding them to the Verisoul SDK for behavioral analysis or
/// fraud detection purposes.
///
/// On Android, it uses a [Listener] to capture pointer events (down, move, up)
/// and sends them to [VerisoulSdk.touchEvent].
///
/// On Web and other platforms, it simply returns the [child] without modification.
class VerisoulWrapper extends StatelessWidget {
  /// The widget subtree to wrap.
  final Widget child;

  /// Creates a [VerisoulWrapper] widget.
  ///
  /// The [child] parameter is required.
  const VerisoulWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return child;
    }

    if (Platform.isAndroid) {
      return Listener(
        behavior: HitTestBehavior.translucent, // Ensures gestures pass through
        onPointerDown: (event) {
          VerisoulSdk.touchEvent(
            x: event.localPosition.dx,
            y: event.localPosition.dy,
            action: MotionAction.down,
          );
        },
        onPointerMove: (event) {
          VerisoulSdk.touchEvent(
            x: event.localPosition.dx,
            y: event.localPosition.dy,
            action: MotionAction.move,
          );
        },
        onPointerUp: (event) {
          VerisoulSdk.touchEvent(
            x: event.localPosition.dx,
            y: event.localPosition.dy,
            action: MotionAction.up,
          );
        },
        child: child,
      );
    }

    return child;
  }
}
