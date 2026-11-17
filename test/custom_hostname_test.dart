import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verisoul_sdk/src/generated/verisoul.api.g.dart';
import 'package:verisoul_sdk/src/verisoul_sdk.dart';

/// The custom hostname passed to configure() reaches the platform side.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      'dev.flutter.pigeon.verisoul_sdk.VerisoulApiHostApi.configure';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  List<Object?>? received;

  setUp(() {
    received = null;
    messenger.setMockMessageHandler(channel, (ByteData? message) async {
      received = VerisoulApiHostApi.pigeonChannelCodec.decodeMessage(message)
          as List<Object?>?;
      return VerisoulApiHostApi.pigeonChannelCodec
          .encodeMessage(<Object?>[null]);
    });
  });

  tearDown(() => messenger.setMockMessageHandler(channel, null));

  test('configure forwards the custom hostname', () async {
    await VerisoulSdk.configure(
      environment: VerisoulEnvironment.prod,
      projectId: 'project-id',
      customHostname: 'js.example.com',
    );

    expect(received, [
      VerisoulEnvironment.prod.index,
      'project-id',
      'js.example.com',
    ]);
  });

  test('configure forwards null when no custom hostname is set', () async {
    await VerisoulSdk.configure(
      environment: VerisoulEnvironment.prod,
      projectId: 'project-id',
    );

    expect(received, [VerisoulEnvironment.prod.index, 'project-id', null]);
  });
}
