import Flutter
import UIKit

public class VerisoulSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      VerisoulApiHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: VerisoulApi());

  }


}
