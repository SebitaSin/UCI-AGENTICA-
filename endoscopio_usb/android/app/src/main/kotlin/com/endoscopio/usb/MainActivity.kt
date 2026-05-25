package com.endoscopio.usb

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CH = "com.endoscopio.usb/camera"
        private const val EVENT_CH  = "com.endoscopio.usb/camera_events"
        private const val USB_PERM  = "com.endoscopio.usb.USB_PERMISSION"
    }

    private lateinit var usbManager: UsbManager
    private var cameraCtrl: UsbCameraController? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingEngine: FlutterEngine? = null

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            when (intent.action) {
                USB_PERM -> {
                    val device = getDevice(intent)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        device?.let { openCamera(it) }
                    } else {
                        sendEvent("error", mapOf("message" to "Permiso USB denegado"))
                        pendingResult?.success(mapOf("connected" to false, "error" to "Permiso denegado"))
                        pendingResult = null
                    }
                }
                UsbManager.ACTION_USB_DEVICE_ATTACHED ->
                    sendEvent("device_attached", emptyMap())
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    cameraCtrl?.stop()
                    cameraCtrl = null
                    sendEvent("device_detached", emptyMap())
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getDevice(intent: Intent): UsbDevice? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
        else intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)

    override fun configureFlutterEngine(@NonNull engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        usbManager = getSystemService(USB_SERVICE) as UsbManager

        val filter = IntentFilter().apply {
            addAction(USB_PERM)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            registerReceiver(usbReceiver, filter, RECEIVER_NOT_EXPORTED)
        else
            registerReceiver(usbReceiver, filter)

        EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CH).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(a: Any?, sink: EventChannel.EventSink?) { eventSink = sink }
                override fun onCancel(a: Any?) { eventSink = null }
            }
        )

        MethodChannel(engine.dartExecutor.binaryMessenger, METHOD_CH).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkDevices" -> result.success(mapOf("hasDevice" to (findUvcDevice() != null)))
                "connect"      -> handleConnect(result, engine)
                "disconnect"   -> { cameraCtrl?.stop(); cameraCtrl = null; result.success(null) }
                "capturePhoto" -> result.success(cameraCtrl?.capturePhoto())
                "startRecording" -> { cameraCtrl?.startRecording(); result.success(null) }
                "stopRecording" -> result.success(cameraCtrl?.stopRecording())
                "setResolution" -> {
                    cameraCtrl?.setResolution(
                        call.argument<Int>("width") ?: 640,
                        call.argument<Int>("height") ?: 480
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleConnect(result: MethodChannel.Result, engine: FlutterEngine) {
        val device = findUvcDevice()
        if (device == null) {
            result.success(mapOf("connected" to false, "error" to "No se encontró endoscopio USB"))
            return
        }
        if (usbManager.hasPermission(device)) {
            startStream(device, result, engine)
        } else {
            pendingResult = result
            pendingEngine = engine
            val pi = PendingIntent.getBroadcast(
                this, 0, Intent(USB_PERM),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            usbManager.requestPermission(device, pi)
        }
    }

    private fun openCamera(device: UsbDevice) {
        val eng = pendingEngine ?: return
        val res = pendingResult
        pendingEngine = null
        pendingResult = null
        startStream(device, res, eng)
    }

    private fun startStream(device: UsbDevice, result: MethodChannel.Result?, engine: FlutterEngine) {
        try {
            val entry = engine.renderer.createSurfaceTexture()
            val ctrl  = UsbCameraController(this, usbManager, entry.surfaceTexture())
            cameraCtrl = ctrl

            ctrl.start(device) { ok, err ->
                runOnUiThread {
                    if (ok) {
                        result?.success(mapOf(
                            "connected"  to true,
                            "textureId"  to entry.id(),
                            "deviceName" to (device.productName ?: "Endoscopio USB"),
                            "vendorId"   to device.vendorId,
                            "productId"  to device.productId,
                        ))
                        sendEvent("stream_started", mapOf("textureId" to entry.id()))
                    } else {
                        result?.success(mapOf("connected" to false, "error" to (err ?: "Error al iniciar")))
                    }
                }
            }
        } catch (e: Exception) {
            result?.success(mapOf("connected" to false, "error" to e.message))
        }
    }

    private fun findUvcDevice(): UsbDevice? =
        usbManager.deviceList.values.firstOrNull { d ->
            d.deviceClass == 0x0E ||
            (d.interfaceCount > 0 && d.getInterface(0).interfaceClass == 0x0E) ||
            d.vendorId in setOf(0x1908, 0x05A3, 0x534D, 0x0AC8, 0x046D, 0x18EC)
        }

    private fun sendEvent(type: String, extra: Map<String, Any?> = emptyMap()) {
        runOnUiThread { eventSink?.success(mapOf("type" to type) + extra) }
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraCtrl?.stop()
        unregisterReceiver(usbReceiver)
    }
}
