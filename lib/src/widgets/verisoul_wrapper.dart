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
      return GestureDetector(
          behavior:
              HitTestBehavior.translucent, // Ensures gestures pass through
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
          child: child);
    }
    return child;
  }
}
