import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';

class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (_, s, __) => Container(
        color: Colors.black.withOpacity(0.88),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Slider('Brillo', Icons.brightness_6, s.brightness, -1.0, 1.0, s.setBrightness, Colors.amber),
            _Slider('Contraste', Icons.contrast, s.contrast, 0.5, 2.0, s.setContrast, Colors.blue),
            _Slider('Nitidez', Icons.blur_linear, s.sharpness, 0.0, 1.0, s.setSharpness, Colors.green),
            _Slider('Zoom', Icons.zoom_in, s.zoom, 1.0, 4.0, s.setZoom, Colors.purple),
            _Slider('Bal. Blanco', Icons.wb_sunny, s.whiteBalance, -1.0, 1.0, s.setWhiteBalance, Colors.orange),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip('Cenit', s.showZenith, s.toggleZenith, Colors.cyan),
                _Chip('Grilla', s.showGrid, s.toggleGrid, Colors.teal),
                _Chip('Cruz', s.showCrosshair, s.toggleCrosshair, Colors.green),
                _Chip('Invertir', s.invertColors, s.toggleInvertColors, Colors.pink),
              ],
            ),
            TextButton.icon(
              onPressed: s.resetAll,
              icon: const Icon(Icons.refresh, size: 15),
              label: const Text('Restablecer', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[400], padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final Color color;
  const _Slider(this.label, this.icon, this.value, this.min, this.max, this.onChanged, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        SizedBox(width: 66, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  const _Chip(this.label, this.active, this.onTap, this.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.22) : Colors.transparent,
          border: Border.all(color: active ? color : Colors.grey[700]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.grey[500],
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
