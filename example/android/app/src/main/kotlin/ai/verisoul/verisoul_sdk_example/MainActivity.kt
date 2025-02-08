package ai.verisoul.verisoul_sdk_example

import ai.verisoul.sdk.Verisoul
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity(){
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        Verisoul.onTouchEvent(event);
        return super.onTouchEvent(event)
    }
}
