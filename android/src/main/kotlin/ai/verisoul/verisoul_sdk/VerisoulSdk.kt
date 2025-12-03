package ai.verisoul.verisoul_sdk

import ai.verisoul.sdk.Verisoul
import ai.verisoul.sdk.VerisoulEnvironment
import ai.verisoul.sdk.VerisoulException
import ai.verisoul.sdk.helpers.webview.VerisoulSessionCallback
import ai.verisoul.verisoul_sdk.generated.FlutterError
import ai.verisoul.verisoul_sdk.generated.VerisoulApiHostApi
import android.content.Context
import android.view.MotionEvent

class VerisoulSdk(val context: Context) : VerisoulApiHostApi {

    // Error codes matching the Flutter SDK constants
    private object ErrorCodes {
        const val WEBVIEW_UNAVAILABLE = "WEBVIEW_UNAVAILABLE"
        const val SESSION_UNAVAILABLE = "SESSION_UNAVAILABLE"
        const val INVALID_ENVIRONMENT = "INVALID_ENVIRONMENT"
        const val UNKNOWN_ERROR = "UNKNOWN_ERROR"
    }

    private val sdkLogLevels: Map<Int, VerisoulEnvironment> = mapOf(
        0 to VerisoulEnvironment.Dev,
        1 to VerisoulEnvironment.Prod,
        2 to VerisoulEnvironment.Sandbox
    )

    private val actions: Map<Int, Int> = mapOf(
        0 to MotionEvent.ACTION_DOWN,
        1 to MotionEvent.ACTION_UP,
        2 to MotionEvent.ACTION_MOVE,
    )

    override fun configure(enviroment: Long, projectId: String, callback: (Result<Unit>) -> Unit) {
        try {
            val logLevel = sdkLogLevels[enviroment.toInt()]
            if (logLevel == null) {
                callback.invoke(
                    Result.failure(
                        FlutterError(
                            ErrorCodes.INVALID_ENVIRONMENT,
                            "Invalid environment: $enviroment",
                            null
                        )
                    )
                )
                return
            }

            Verisoul.init(context, logLevel, projectId)
            callback.invoke(Result.success(Unit))

        } catch (e: VerisoulException) {
            callback.invoke(Result.failure(FlutterError(e.code, e.message, null)))
        } catch (e: Exception) {
            callback.invoke(
                Result.failure(
                    FlutterError(
                        ErrorCodes.UNKNOWN_ERROR,
                        e.message ?: "Failed to configure Verisoul SDK",
                        null
                    )
                )
            )
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
            e.printStackTrace()
        }
    }

    override fun getSessionId(callback: (Result<String>) -> Unit) {
        try {
            Verisoul.getSessionId(object : VerisoulSessionCallback {
                override fun onFailure(exception: Throwable) {
                    if (exception is VerisoulException) {
                        callback.invoke(
                            Result.failure(
                                FlutterError(
                                    exception.code,
                                    exception.message,
                                    null
                                )
                            )
                        )
                    } else {
                        callback.invoke(
                            Result.failure(
                                FlutterError(
                                    ErrorCodes.SESSION_UNAVAILABLE,
                                    exception.message ?: "Failed to retrieve session ID",
                                    null
                                )
                            )
                        )
                    }
                }


                override fun onSuccess(sessionId: String) {
                    callback.invoke(Result.success(sessionId))
                }
            })
        } catch (e: VerisoulException) {
            callback.invoke(
                Result.failure(
                    FlutterError(
                        e.code,
                        e.message,
                        null
                    )
                )
            )
        } catch (e: Throwable) {
            callback.invoke(
                Result.failure(
                    FlutterError(
                        ErrorCodes.SESSION_UNAVAILABLE,
                        e.message ?: "Failed to retrieve session ID",
                        null
                    )
                )
            )
        }
    }

    override fun reinitialize(callback: (Result<Unit>) -> Unit) {
        try {
            Verisoul.reinitialize()
            callback.invoke(Result.success(Unit))
        } catch (e: VerisoulException) {
            callback.invoke(Result.failure(FlutterError(e.code, e.message, null)))
        } catch (e: Exception) {
            callback.invoke(
                Result.failure(
                    FlutterError(
                        ErrorCodes.UNKNOWN_ERROR,
                        e.message ?: "Failed to reinitialize Verisoul SDK",
                        null
                    )
                )
            )
        }
    }

    override fun setAccountData(account: Map<String, Any?>) {
    }
}