package com.example.bolusbuddy_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var depthManager: DepthCaptureManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        depthManager = DepthCaptureManager(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bolusbuddy/depth")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDepthCapabilities" -> {
                        val capabilities = depthManager.getCapabilities()
                        result.success(
                            mapOf(
                                "hasDepth" to capabilities.hasDepth,
                                "depthType" to capabilities.depthType,
                                "supportsConfidence" to capabilities.supportsConfidence
                            )
                        )
                    }
                    "captureDepthFrame" -> {
                        Thread {
                            try {
                                val capture = depthManager.captureDepthFrame()
                                result.success(
                                    mapOf(
                                        "rgbJpeg" to capture.rgbJpeg,
                                        "depthPng16" to null,
                                        "depthF32" to capture.depthF32,
                                        "depthEncoding" to capture.depthEncoding,
                                        "confidencePng" to capture.confidencePng,
                                        "intrinsicsJson" to capture.intrinsicsJson,
                                        "width" to capture.width,
                                        "height" to capture.height
                                    )
                                )
                            } catch (ex: Exception) {
                                result.error("DEPTH_CAPTURE_FAILED", ex.localizedMessage, null)
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
