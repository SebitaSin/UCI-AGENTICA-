import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/usb_camera_service.dart';
import '../models/app_settings.dart';
import '../widgets/zenith_overlay.dart';
import '../widgets/controls_panel.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _showControls = false;
  double _baseZoom = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer2<UsbCameraService, AppSettings>(
          builder: (_, camera, settings, __) {
            return GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              onDoubleTap: () => settings.setZoom(settings.zoom > 1.5 ? 1.0 : 2.0),
              onScaleStart: (_) => _baseZoom = settings.zoom,
              onScaleUpdate: (d) {
                if ((d.scale - 1.0).abs() > 0.02) {
                  settings.setZoom(_baseZoom * d.scale);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildFeed(camera, settings),
                  ZenithOverlay(settings: settings),
                  _buildTopBar(camera, settings),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showControls) const ControlsPanel(),
                        _buildToolbar(camera, settings),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeed(UsbCameraService camera, AppSettings settings) {
    if (!camera.isStreaming || camera.textureId == null) {
      return _buildDisconnected(camera);
    }
    Widget feed = Transform.scale(
      scale: settings.zoom,
      child: Texture(textureId: camera.textureId!),
    );
    if (settings.brightness != 0.0 || settings.contrast != 1.0 || settings.invertColors) {
      feed = ColorFiltered(
        colorFilter: _colorFilter(settings),
        child: feed,
      );
    }
    return feed;
  }

  ColorFilter _colorFilter(AppSettings s) {
    if (s.invertColors) {
      return const ColorFilter.matrix([
        -1, 0, 0, 0, 255,
         0,-1, 0, 0, 255,
         0, 0,-1, 0, 255,
         0, 0, 0, 1, 0,
      ]);
    }
    final c = s.contrast;
    final t = s.brightness * 128 + 128 * (1 - c);
    return ColorFilter.matrix([
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ]);
  }

  Widget _buildDisconnected(UsbCameraService camera) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.usb, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 20),
          Text(
            camera.statusMessage,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: camera.connectCamera,
            icon: const Icon(Icons.link),
            label: const Text('Conectar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(UsbCameraService camera, AppSettings settings) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: camera.isStreaming ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                camera.statusMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_showControls)
              PopupMenuButton<ZenithStyle>(
                icon: const Icon(Icons.navigation, color: Colors.white70, size: 20),
                color: Colors.grey[900],
                tooltip: 'Estilo cenit',
                onSelected: settings.setZenithStyle,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: ZenithStyle.crosshair, child: Text('Cruz de mira', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: ZenithStyle.compass,   child: Text('Brújula',      style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: ZenithStyle.circle,    child: Text('Círculos',      style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: ZenithStyle.dot,       child: Text('Punto',         style: TextStyle(color: Colors.white))),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(UsbCameraService camera, AppSettings settings) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.75), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolBtn(
            icon: camera.isConnected ? Icons.link_off : Icons.link,
            label: camera.isConnected ? 'Desconectar' : 'Conectar',
            color: camera.isConnected ? Colors.orange : Colors.green,
            onTap: camera.isConnected ? camera.disconnect : camera.connectCamera,
          ),
          _CaptureBtn(onTap: () async {
            final path = await camera.capturePhoto();
            if (path != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto guardada'), duration: Duration(seconds: 2)),
              );
            }
          }),
          _ToolBtn(
            icon: camera.isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
            label: camera.isRecording ? 'Detener' : 'Grabar',
            color: camera.isRecording ? Colors.red : Colors.white70,
            onTap: () {
              if (camera.isRecording) camera.stopRecording();
              else camera.startRecording();
            },
          ),
          _ToolBtn(
            icon: Icons.zoom_out_map,
            label: 'x${settings.zoom.toStringAsFixed(1)}',
            color: settings.zoom > 1.0 ? Colors.cyan : Colors.white54,
            onTap: () => settings.setZoom(1.0),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CaptureBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _CaptureBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62, height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.white.withOpacity(0.12),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),
    );
  }
}
