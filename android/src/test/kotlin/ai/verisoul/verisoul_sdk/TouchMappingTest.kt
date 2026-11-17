package ai.verisoul.verisoul_sdk

import android.view.MotionEvent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Touch events sent from Dart map onto the right MotionEvent values. */
internal class TouchMappingTest {

    // Index order of the Dart MotionAction enum: up, down, move.
    private val dartUp = 0
    private val dartDown = 1
    private val dartMove = 2

    @Test
    fun dartDown_mapsToActionDown() {
        assertEquals(MotionEvent.ACTION_DOWN, TouchMapping.motionActionFor(dartDown))
    }

    @Test
    fun dartUp_mapsToActionUp() {
        assertEquals(MotionEvent.ACTION_UP, TouchMapping.motionActionFor(dartUp))
    }

    @Test
    fun dartMove_mapsToActionMove() {
        assertEquals(MotionEvent.ACTION_MOVE, TouchMapping.motionActionFor(dartMove))
    }

    @Test
    fun unknownIndex_mapsToNull() {
        assertNull(TouchMapping.motionActionFor(3))
        assertNull(TouchMapping.motionActionFor(-1))
    }

    @Test
    fun logicalPixels_scaleByDensity() {
        assertEquals(1080f, TouchMapping.toPhysicalPixels(411.428571, 2.625f), 0.01f)
        assertEquals(100f, TouchMapping.toPhysicalPixels(100.0, 1f), 0f)
    }
}
