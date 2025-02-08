import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class VerisoulApiHostApi {
  void configure(int enviromentVariable, String projectId);

  void onTouchEvent(double x, double y, int motionType);

  @async
  String getSessionId();
}
