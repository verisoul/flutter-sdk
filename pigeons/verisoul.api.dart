import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class VerisoulApiHostApi {
  void configure(int enviromentVariable, String projectId, bool reinitialize);

  void onTouchEvent(double x, double y, int motionType);

  @async
  String getSessionId();
  void reinitialize();
  void setAccountData(Map<String, Object?> account);
}
