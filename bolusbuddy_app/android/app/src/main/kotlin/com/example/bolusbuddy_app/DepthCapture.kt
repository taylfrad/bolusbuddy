package com.example.bolusbuddy_app

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.Image
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Session
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.zip.GZIPOutputStream
import org.json.JSONObject

data class DepthCapabilities(
    val hasDepth: Boolean,
    val depthType: String,
    val supportsConfidence: Boolean
)

data class DepthCaptureResult(
    val rgbJpeg: ByteArray,
    val depthF32: ByteArray?,
    val depthEncoding: String?,
    val confidencePng: ByteArray?,
    val intrinsicsJson: String,
    val width: Int,
    val height: Int
)

class DepthCaptureManager(private val activity: Activity) {
    private var session: Session? = null

    fun getCapabilities(): DepthCapabilities {
        return try {
            val session = Session(activity)
            val supported = session.isDepthModeSupported(Config.DepthMode.AUTOMATIC)
            session.close()
            DepthCapabilities(
                hasDepth = supported,
                depthType = if (supported) "arcore_depth" else "none",
                supportsConfidence = supported
            )
        } catch (ex: Exception) {
            DepthCapabilities(hasDepth = false, depthType = "none", supportsConfidence = false)
        }
    }

    fun captureDepthFrame(): DepthCaptureResult {
        val session = ensureSession()
        val frame = session.update()
        val cameraImage = frame.acquireCameraImage()
        val rgbJpeg = yuvToJpeg(cameraImage)
        cameraImage.close()

        val depthImage = try {
            frame.acquireDepthImage16Bits()
        } catch (ex: Exception) {
            null
        }
        val depthBytes = depthImage?.let { depthToCompressedF32(it) }
        depthImage?.close()

        val confidenceImage = try {
            frame.acquireDepthConfidenceImage()
        } catch (ex: Exception) {
            null
        }
        val confidencePng = confidenceImage?.let { confidenceToPng(it) }
        confidenceImage?.close()

        val intrinsics = frame.camera.imageIntrinsics
        val dimensions = intrinsics.imageDimensions
        val intrinsicsJson = JSONObject(
            mapOf(
                "fx" to intrinsics.focalLength[0],
                "fy" to intrinsics.focalLength[1],
                "cx" to intrinsics.principalPoint[0],
                "cy" to intrinsics.principalPoint[1]
            )
        ).toString()

        return DepthCaptureResult(
            rgbJpeg = rgbJpeg,
            depthF32 = depthBytes,
            depthEncoding = if (depthBytes != null) "f32_gzip" else null,
            confidencePng = confidencePng,
            intrinsicsJson = intrinsicsJson,
            width = dimensions[0],
            height = dimensions[1]
        )
    }

    private fun ensureSession(): Session {
        if (session == null) {
            session = Session(activity)
            val config = Config(session)
            if (session!!.isDepthModeSupported(Config.DepthMode.AUTOMATIC)) {
                config.depthMode = Config.DepthMode.AUTOMATIC
            }
            session!!.configure(config)
            session!!.resume()
        }
        return session!!
    }

    private fun yuvToJpeg(image: Image): ByteArray {
        val nv21 = yuv420ToNv21(image)
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
        val outputStream = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, image.width, image.height), 85, outputStream)
        return outputStream.toByteArray()
    }

    private fun yuv420ToNv21(image: Image): ByteArray {
        val width = image.width
        val height = image.height
        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]
        val nv21 = ByteArray(width * height * 3 / 2)

        val yBuffer = yPlane.buffer.duplicate()
        val uBuffer = uPlane.buffer.duplicate()
        val vBuffer = vPlane.buffer.duplicate()

        var position = 0
        for (row in 0 until height) {
            val rowStart = row * yPlane.rowStride
            for (col in 0 until width) {
                val index = rowStart + col * yPlane.pixelStride
                nv21[position++] = yBuffer.get(index)
            }
        }

        val uvHeight = height / 2
        val uvWidth = width / 2
        for (row in 0 until uvHeight) {
            val rowStart = row * uPlane.rowStride
            for (col in 0 until uvWidth) {
                val uIndex = rowStart + col * uPlane.pixelStride
                val vIndex = rowStart + col * vPlane.pixelStride
                nv21[position++] = vBuffer.get(vIndex)
                nv21[position++] = uBuffer.get(uIndex)
            }
        }
        return nv21
    }

    private fun depthToCompressedF32(image: Image): ByteArray {
        val plane = image.planes[0]
        val buffer = plane.buffer.order(ByteOrder.nativeOrder())
        val width = image.width
        val height = image.height
        val floatBuffer = ByteBuffer.allocate(width * height * 4).order(ByteOrder.LITTLE_ENDIAN)
        for (row in 0 until height) {
            val rowStart = row * plane.rowStride
            for (col in 0 until width) {
                val index = rowStart + col * plane.pixelStride
                val depthMillimeters = buffer.getShort(index).toInt() and 0xFFFF
                val depthMeters = depthMillimeters / 1000.0f
                floatBuffer.putFloat(depthMeters)
            }
        }
        val raw = floatBuffer.array()
        val compressed = ByteArrayOutputStream()
        GZIPOutputStream(compressed).use { it.write(raw) }
        return compressed.toByteArray()
    }

    private fun confidenceToPng(image: Image): ByteArray {
        val buffer = image.planes[0].buffer
        val bitmap = Bitmap.createBitmap(image.width, image.height, Bitmap.Config.ALPHA_8)
        bitmap.copyPixelsFromBuffer(buffer)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
