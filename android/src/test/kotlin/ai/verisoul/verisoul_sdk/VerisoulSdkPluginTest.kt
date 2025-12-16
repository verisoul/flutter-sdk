package ai.verisoul.verisoul_sdk

import kotlin.test.Test
import kotlin.test.assertNotNull

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class VerisoulSdkPluginTest {
  @Test
  fun plugin_instantiates() {
    // The plugin is Pigeon-based (no MethodChannel onMethodCall handler anymore).
    // This is a minimal smoke test to ensure the class is present and constructible.
    assertNotNull(VerisoulSdkPlugin())
  }
}
