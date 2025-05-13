package ai.verisoul.verisoul_sdk

import ai.verisoul.verisoul_sdk.generated.VerisoulApiHostApi
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** VerisoulSdkPlugin */
class VerisoulSdkPlugin : FlutterPlugin {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        VerisoulApiHostApi.setUp(
            flutterPluginBinding.binaryMessenger,
            VerisoulSdk(flutterPluginBinding.applicationContext)
        );
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {

    }
}
