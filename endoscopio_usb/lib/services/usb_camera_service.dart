import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsbDeviceInfo {
  final String name;
  final int vendorId;
  final int productId;
  const UsbDeviceInfo({required this.name, required this.vendorId, required this.productId});
}

class UsbCameraService extends ChangeNotifier {
  static const _method = MethodChannel('com.endoscopio.usb/camera');
  static const _events = EventChannel('com.endoscopio.usb/camera_events');

  bool _isConnected = false;
  bool _isStreaming = false;
  bool _isRecording = false;
  int? _textureId;
  String _statusMessage = 'Conectá el endoscopio al puerto USB';
  UsbDeviceInfo? _connectedDevice;
  StreamSubscription? _eventSub;

  bool get isConnected => _isConnected;
  bool get isStreaming => _isStreaming;
  bool get isRecording => _isRecording;
  int? get textureId => _textureId;
  String get statusMessage => _statusMessage;
  UsbDeviceInfo? get connectedDevice => _connectedDevice;

  UsbCameraService() {
    _listenEvents();
    _checkDevices();
  }

  void _listenEvents() {
    _eventSub = _events.receiveBroadcastStream().listen(
      (event) => _handleEvent(Map<String, dynamic>.from(event as Map)),
      onError: (_) { _statusMessage = 'Error de conexión'; notifyListeners(); },
    );
  }

  void _handleEvent(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'device_attached':
        _statusMessage = 'Endoscopio detectado. Conectando...';
        notifyListeners();
        connectCamera();
        break;
      case 'device_detached':
        _isConnected = false;
        _isStreaming = false;
        _textureId = null;
        _connectedDevice = null;
        _statusMessage = 'Endoscopio desconectado';
        notifyListeners();
        break;
      case 'stream_started':
        _isStreaming = true;
        _textureId = e['textureId'] as int?;
        _statusMessage = 'Transmitiendo';
        notifyListeners();
        break;
      case 'error':
        _statusMessage = e['message'] as String? ?? 'Error desconocido';
        notifyListeners();
        break;
    }
  }

  Future<void> _checkDevices() async {
    try {
      final result = await _method.invokeMethod<Map>('checkDevices');
      if (result != null && result['hasDevice'] == true) {
        _statusMessage = 'Endoscopio encontrado. Conectando...';
        notifyListeners();
        await connectCamera();
      }
    } catch (_) {}
  }

  Future<void> connectCamera() async {
    try {
      _statusMessage = 'Solicitando permiso USB...';
      notifyListeners();
      final result = await _method.invokeMethod<Map>('connect');
      if (result == null) return;
      _isConnected = result['connected'] == true;
      if (_isConnected) {
        _textureId = result['textureId'] as int?;
        _isStreaming = true;
        _connectedDevice = UsbDeviceInfo(
          name: result['deviceName'] as String? ?? 'Endoscopio USB',
          vendorId: result['vendorId'] as int? ?? 0,
          productId: result['productId'] as int? ?? 0,
        );
        _statusMessage = 'Conectado: ${_connectedDevice!.name}';
      } else {
        _statusMessage = result['error'] as String? ?? 'No se pudo conectar';
      }
      notifyListeners();
    } on PlatformException catch (e) {
      _statusMessage = 'Error: ${e.message}';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _method.invokeMethod('disconnect');
    } catch (_) {}
    _isConnected = false;
    _isStreaming = false;
    _textureId = null;
    _statusMessage = 'Desconectado';
    notifyListeners();
  }

  Future<String?> capturePhoto() async {
    try { return await _method.invokeMethod<String>('capturePhoto'); }
    catch (_) { return null; }
  }

  Future<void> startRecording() async {
    try {
      await _method.invokeMethod('startRecording');
      _isRecording = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _method.invokeMethod<String>('stopRecording');
      _isRecording = false;
      notifyListeners();
      return path;
    } catch (_) {
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> setResolution(int width, int height) async {
    try { await _method.invokeMethod('setResolution', {'width': width, 'height': height}); }
    catch (_) {}
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    disconnect();
    super.dispose();
  }
}
