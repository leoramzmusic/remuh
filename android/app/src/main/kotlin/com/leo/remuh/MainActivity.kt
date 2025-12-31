package com.leo.remuh

import android.media.audiofx.Equalizer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "remuh/eq"
    private var equalizer: Equalizer? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    }

    private fun initEq(sessionId: Int): Boolean {
        return try {
            equalizer?.release()
            equalizer = Equalizer(0, sessionId)
            equalizer?.enabled = true
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getBandInfo(): List<Map<String, Any>> {
        val eq = equalizer ?: return emptyList()
        val bandCount = eq.numberOfBands.toInt()
        val result = mutableListOf<Map<String, Any>>()
        for (b in 0 until bandCount) {
            val range = eq.bandLevelRange // [min, max] in mB (millibels)
            val center = eq.getCenterFreq(b.toShort()) // in mHz
            result.add(
                mapOf(
                    "band" to b,
                    "minMb" to range[0].toInt(),
                    "maxMb" to range[1].toInt(),
                    "centerHz" to (center / 1000).toInt()
                )
            )
        }
        return result
    }

    private fun setBandLevel(band: Int, levelMb: Int) {
        equalizer?.setBandLevel(band.toShort(), levelMb.toShort())
    }

    private fun releaseEq() {
        equalizer?.release()
        equalizer = null
    }
}
