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
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        VerisoulApiHostApi.setUp(
            flutterPluginBinding.binaryMessenger,
            VerisoulSdk(flutterPluginBinding.applicationContext)
        );
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
