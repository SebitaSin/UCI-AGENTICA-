import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/usb_camera_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Configuración', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<AppSettings, UsbCameraService>(
        builder: (_, settings, camera, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section('Cámara', [
                _InfoTile(Icons.videocam, 'Dispositivo',
                    camera.connectedDevice?.name ?? 'No conectado'),
                _ActionTile(Icons.aspect_ratio, 'Resolución',
                    'Cambiar resolución del stream',
                    () => _resolutionDialog(context, camera)),
              ]),
              _Section('Superposición', [
                _Switch(Icons.navigation, 'Marcador de Cenit',
                    settings.showZenith, (_) => settings.toggleZenith()),
                _Switch(Icons.add, 'Retícula central',
                    settings.showCrosshair, (_) => settings.toggleCrosshair()),
                _Switch(Icons.grid_on, 'Grilla de tercios',
                    settings.showGrid, (_) => settings.toggleGrid()),
                _Switch(Icons.invert_colors, 'Invertir colores',
                    settings.invertColors, (_) => settings.toggleInvertColors()),
              ]),
              _Section('Estilo de Cenit', [
                _Radio('Cruz de mira', ZenithStyle.crosshair, settings.zenithStyle, settings.setZenithStyle),
                _Radio('Brújula N/S/E/O', ZenithStyle.compass, settings.zenithStyle, settings.setZenithStyle),
                _Radio('Círculos concéntricos', ZenithStyle.circle, settings.zenithStyle, settings.setZenithStyle),
                _Radio('Punto central', ZenithStyle.dot, settings.zenithStyle, settings.setZenithStyle),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: settings.resetAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Restablecer todo'),
                style: FilledButton.styleFrom(backgroundColor: Colors.grey[800]),
              ),
            ],
          );
        },
      ),
    );
  }

  void _resolutionDialog(BuildContext ctx, UsbCameraService camera) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Resolución', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in [('640 × 480 (VGA)', 640, 480), ('1280 × 720 (HD)', 1280, 720), ('1920 × 1080 (Full HD)', 1920, 1080)])
              ListTile(
                title: Text(r.$1, style: const TextStyle(color: Colors.white)),
                onTap: () { camera.setResolution(r.$2, r.$3); Navigator.pop(_); },
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(color: Colors.cyan[300], fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
        ),
        Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _InfoTile(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Colors.cyan[300]),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.title, this.subtitle, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Colors.cyan[300]),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right, color: Colors.white38),
    onTap: onTap,
  );
}

class _Switch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Switch(this.icon, this.title, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: Colors.cyan[300]),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    value: value,
    activeColor: Colors.cyan,
    onChanged: onChanged,
  );
}

class _Radio extends StatelessWidget {
  final String title;
  final ZenithStyle value, groupValue;
  final ValueChanged<ZenithStyle> onChanged;
  const _Radio(this.title, this.value, this.groupValue, this.onChanged);
  @override
  Widget build(BuildContext context) => RadioListTile<ZenithStyle>(
    title: Text(title, style: const TextStyle(color: Colors.white)),
    value: value,
    groupValue: groupValue,
    activeColor: Colors.cyan,
    onChanged: (v) { if (v != null) onChanged(v); },
  );
}
