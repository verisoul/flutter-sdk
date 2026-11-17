package ai.verisoul.verisoul_sdk

import android.view.MotionEvent

/**
 * Maps touch events sent from Dart onto Android MotionEvent values.
 * Kept free of Android runtime calls so plain JVM unit tests can cover it.
 */
internal object TouchMapping {

    /**
     * Converts the index of the Dart `MotionAction` enum (`up`, `down`, `move`)
     * to a MotionEvent action. Returns null for an unknown index.
     */
    fun motionActionFor(dartIndex: Int): Int? = when (dartIndex) {
        0 -> MotionEvent.ACTION_UP
        1 -> MotionEvent.ACTION_DOWN
        2 -> MotionEvent.ACTION_MOVE
        else -> null
    }

    /** Converts a Flutter logical pixel value to physical pixels. */
    fun toPhysicalPixels(logical: Double, density: Float): Float =
        (logical * density).toFloat()
}
