package ai.verisoul.verisoul_sdk

import ai.verisoul.sdk.Verisoul
import ai.verisoul.sdk.VerisoulEnvironment
import ai.verisoul.sdk.helpers.webview.VerisoulSessionCallback
import ai.verisoul.verisoul_sdk.generated.VerisoulApiHostApi
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.MotionEvent

class VerisoulSdk(val context: Context) : VerisoulApiHostApi {

    private val sdkLogLevels: Map<Int, VerisoulEnvironment> = mapOf(
        0 to VerisoulEnvironment.Dev,
        1 to VerisoulEnvironment.Prod,
        2 to VerisoulEnvironment.Sandbox,
        3 to VerisoulEnvironment.Sandbox
    )

    private val actions: Map<Int, Int> = mapOf(
        0 to MotionEvent.ACTION_DOWN,
        1 to MotionEvent.ACTION_UP,
        2 to MotionEvent.ACTION_MOVE,

        )


    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configure(enviroment: Long, projectId: String) {
        mainHandler.post {
            try {
                val logLevel = sdkLogLevels[enviroment.toInt()]
                    ?: throw IllegalArgumentException("Invalid environment: $enviroment")

                Verisoul.init(context, logLevel, projectId)

            } catch (e: Exception) {
                e.printStackTrace();
            }
        }
    }

    override fun onTouchEvent(x: Double, y: Double, motionType: Long) {
        try {
            val motionEvent = MotionEvent.obtain(
                System.currentTimeMillis(),
                System.currentTimeMillis(),
                actions[motionType.toInt()]!!,
                x.toFloat(),
                y.toFloat(),
                0
            )
            Verisoul.onTouchEvent(motionEvent)

        } catch (e: Exception) {
            e.printStackTrace();
        }
    }

    override fun getSessionId(callback: (Result<String>) -> Unit) {
        mainHandler.post {
            try {
                Verisoul.getSessionId(object : VerisoulSessionCallback {
                    override fun onFailure(exception: Exception) {
                        callback.invoke(Result.failure(exception))
                    }

                    override fun onSuccess(sessionId: String) {
                        callback.invoke(Result.success(sessionId))
                    }
                })
            } catch (e: Exception) {
                callback.invoke(Result.failure(e))
            }
        }
    }

    override fun reinitialize() {
        mainHandler.post {
            try {
                Verisoul.reinitialize()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

    }

    override fun setAccountData(account: Map<String, Any?>) {
    }
}