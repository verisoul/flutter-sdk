import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verisoul_sdk/src/generated/verisoul.api.g.dart';
import 'package:verisoul_sdk/verisoul_sdk.dart';

/// VerisoulWrapper forwards one press per gesture, at its screen position.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      'dev.flutter.pigeon.verisoul_sdk.VerisoulApiHostApi.onTouchEvent';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final received = <List<Object?>>[];

  setUp(() {
    received.clear();
    messenger.setMockMessageHandler(channel, (ByteData? message) async {
      received.add(VerisoulApiHostApi.pigeonChannelCodec.decodeMessage(message)
          as List<Object?>);
      return VerisoulApiHostApi.pigeonChannelCodec
          .encodeMessage(<Object?>[null]);
    });
  });

  tearDown(() => messenger.setMockMessageHandler(channel, null));

  // The wrapped child sits 50 logical pixels below the top of the screen, so
  // a screen position differs from a position local to the wrapper.
  Widget app() => const Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.only(top: 50),
          child: VerisoulWrapper(child: SizedBox.expand()),
        ),
      );

  testWidgets('a tap forwards one down event at its screen position',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.tapAt(const Offset(120, 300));
    await tester.pump();

    expect(received, [
      [120.0, 300.0, MotionAction.down.index],
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a drag forwards the press only', (tester) async {
    await tester.pumpWidget(app());

    await tester.dragFrom(const Offset(100, 200), const Offset(0, 150));
    await tester.pump();

    expect(received, [
      [100.0, 200.0, MotionAction.down.index],
    ]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  test('down keeps the index the Android side expects', () {
    expect(MotionAction.up.index, 0);
    expect(MotionAction.down.index, 1);
    expect(MotionAction.move.index, 2);
  });
}
