import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';

class VerisoulWrapper extends StatelessWidget {
  final Widget child;

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
