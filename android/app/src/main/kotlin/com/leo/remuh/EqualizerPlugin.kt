package com.leo.remuh

import android.media.audiofx.Equalizer
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class EqualizerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var equalizer: Equalizer? = null
    private var currentSessionId: Int = -1
    private val CHANNEL_NAME = "remuh/eq"

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initEq" -> {
                val sessionId = call.argument<Int>("sessionId") ?: 0
                val success = initEq(sessionId)
                result.success(success)
            }
            "getBands" -> {
                result.success(getBandInfo())
            }
            "setBandLevel" -> {
                val band = call.argument<Int>("band") ?: 0
                val levelMb = call.argument<Int>("levelMb") ?: 0
                setBandLevel(band, levelMb)
                result.success(null)
            }
            "release" -> {
                releaseEq()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseEq()
    }

    private fun initEq(sessionId: Int): Boolean {
        if (equalizer != null && currentSessionId == sessionId && sessionId != 0) {
            android.util.Log.d(
                    "EqualizerPlugin",
                    "EQ already initialized for sessionId: $sessionId"
            )
            return true
        }

        android.util.Log.d("EqualizerPlugin", "Initializing EQ with sessionId: $sessionId")
        return try {
            equalizer?.release()
            currentSessionId = -1

            var success = false
            // Try different priorities and session IDs
            val attemptConfigs = listOf(Pair(10, sessionId), Pair(0, sessionId), Pair(0, 0))

            for (config in attemptConfigs) {
                try {
                    equalizer = Equalizer(config.first, config.second)
                    currentSessionId = config.second
                    success = true
                    android.util.Log.d(
                            "EqualizerPlugin",
                            "EQ initialized with priority ${config.first} and session ${config.second}"
                    )
                    break
                } catch (e: Exception) {
                    android.util.Log.w(
                            "EqualizerPlugin",
                            "Failed attempt with priority ${config.first} and session ${config.second}"
                    )
                }
            }

            if (success) {
                equalizer?.enabled = true
                android.util.Log.d(
                        "EqualizerPlugin",
                        "EQ enabled successfully. Bands: ${equalizer?.numberOfBands}"
                )
            }
            success
        } catch (e: Exception) {
            android.util.Log.e("EqualizerPlugin", "Critical error in initEq", e)
            false
        }
    }

    private fun getBandInfo(): List<Map<String, Any>> {
        return try {
            val eq = equalizer ?: return emptyList()
            val bandCount = eq.numberOfBands.toInt()
            val range = eq.bandLevelRange // Cache range outside loop
            val minMb = range[0].toInt()
            val maxMb = range[1].toInt()

            val result = mutableListOf<Map<String, Any>>()
            for (b in 0 until bandCount) {
                val center = eq.getCenterFreq(b.toShort()) // in mHz
                result.add(
                        mapOf(
                                "band" to b,
                                "minMb" to minMb,
                                "maxMb" to maxMb,
                                "centerHz" to (center / 1000).toInt()
                        )
                )
            }
            result
        } catch (e: Exception) {
            android.util.Log.e("EqualizerPlugin", "Error getting band info", e)
            emptyList()
        }
    }

    private fun setBandLevel(band: Int, levelMb: Int) {
        equalizer?.setBandLevel(band.toShort(), levelMb.toShort())
    }

    private fun releaseEq() {
        equalizer?.release()
        equalizer = null
        currentSessionId = -1
    }
}
