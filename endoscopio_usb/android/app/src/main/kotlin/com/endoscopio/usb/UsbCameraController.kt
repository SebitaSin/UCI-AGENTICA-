package com.endoscopio.usb

import android.content.Context
import android.graphics.SurfaceTexture
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import android.os.Environment
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Controls USB (UVC) camera streaming to a Flutter SurfaceTexture.
 *
 * For full UVC frame decoding integrate:
 *   com.github.jiangdongguo.AndroidUSBCamera:libausbc:3.3.3
 * and replace the startFrameLoop stub with MultiCameraClient.
 */
class UsbCameraController(
    private val context: Context,
    private val usbManager: UsbManager,
    private val surfaceTexture: SurfaceTexture,
) {
    private var connection: UsbDeviceConnection? = null
    private var isStreaming = false
    private var isRecording = false
    private var recordingPath: String? = null

    fun start(device: UsbDevice, callback: (Boolean, String?) -> Unit) {
        Thread {
            try {
                connection = usbManager.openDevice(device)
                    ?: return@Thread callback(false, "No se pudo abrir el dispositivo USB")

                // Claim UVC interface (class 0x0E = Video)
                var claimed = false
                for (i in 0 until device.interfaceCount) {
                    val iface = device.getInterface(i)
                    if (iface.interfaceClass == 0x0E || i == 0) {
                        connection!!.claimInterface(iface, true)
                        claimed = true
                        if (iface.interfaceClass == 0x0E) break
                    }
                }

                if (!claimed) {
                    return@Thread callback(false, "No se pudo reclamar la interfaz USB")
                }

                surfaceTexture.setDefaultBufferSize(640, 480)
                isStreaming = true

                // Full UVC frame streaming requires native UVC negotiation.
                // Integrate libausbc (AndroidUSBCamera) here for production use.
                callback(true, null)

            } catch (e: Exception) {
                callback(false, e.message ?: "Error inesperado")
            }
        }.start()
    }

    fun capturePhoto(): String? = runCatching {
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES) ?: return null
        val ts  = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val f   = File(dir, "endo_$ts.jpg")
        // With libausbc: capture bitmap from camera and save via BitmapFactory
        f.absolutePath
    }.getOrNull()

    fun startRecording(): Boolean {
        if (isRecording) return false
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES) ?: return false
        val ts  = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        recordingPath = File(dir, "endo_$ts.mp4").absolutePath
        isRecording = true
        return true
    }

    fun stopRecording(): String? {
        if (!isRecording) return null
        isRecording = false
        return recordingPath
    }

    fun setResolution(width: Int, height: Int) {
        surfaceTexture.setDefaultBufferSize(width, height)
    }

    fun stop() {
        isStreaming = false
        isRecording = false
        runCatching { connection?.close() }
        connection = null
    }
}
