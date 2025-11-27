import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class VerisoulApiHostApi {
  @async
  void configure(int enviromentVariable, String projectId);

  void onTouchEvent(double x, double y, int motionType);

  @async
  String getSessionId();

  @async
  void reinitialize();

  void setAccountData(Map<String, Object?> account);
}
