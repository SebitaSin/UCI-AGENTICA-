import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class ZenithOverlay extends StatelessWidget {
  final AppSettings settings;
  const ZenithOverlay({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ZenithPainter(settings: settings),
      child: const SizedBox.expand(),
    );
  }
}

class _ZenithPainter extends CustomPainter {
  final AppSettings settings;
  _ZenithPainter({required this.settings});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    if (settings.showGrid) _drawGrid(canvas, size);
    if (settings.showCrosshair) _drawCrosshair(canvas, size, cx, cy);
    if (settings.showZenith) {
      switch (settings.zenithStyle) {
        case ZenithStyle.crosshair: _drawZenithRing(canvas, size, cx, cy);
        case ZenithStyle.compass:   _drawCompass(canvas, size, cx, cy);
        case ZenithStyle.circle:    _drawCircles(canvas, size, cx, cy);
        case ZenithStyle.dot:       _drawDot(canvas, cx, cy);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), p);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), p);
    }
  }

  void _drawCrosshair(Canvas canvas, Size size, double cx, double cy) {
    final p = Paint()..color = Colors.green.withOpacity(0.6)..strokeWidth = 1.0;
    const gap = 22.0;
    canvas.drawLine(Offset(0, cy), Offset(cx - gap, cy), p);
    canvas.drawLine(Offset(cx + gap, cy), Offset(size.width, cy), p);
    canvas.drawLine(Offset(cx, 0), Offset(cx, cy - gap), p);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, size.height), p);
  }

  void _drawZenithRing(Canvas canvas, Size size, double cx, double cy) {
    final p = Paint()..color = Colors.cyan.withOpacity(0.9)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final r = size.width * 0.06;
    canvas.drawCircle(Offset(cx, cy), r, p);
    final tick = r * 0.5;
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2;
      canvas.drawLine(
        Offset(cx + (r + 3) * cos(a), cy + (r + 3) * sin(a)),
        Offset(cx + (r + 3 + tick) * cos(a), cy + (r + 3 + tick) * sin(a)),
        p,
      );
    }
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.cyan);
  }

  void _drawCompass(Canvas canvas, Size size, double cx, double cy) {
    final p = Paint()..color = Colors.green.withOpacity(0.85)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final r = size.width * 0.12;
    canvas.drawCircle(Offset(cx, cy), r, p);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    const labels = ['N', 'E', 'S', 'O'];
    for (int i = 0; i < 4; i++) {
      final a = i * pi / 2 - pi / 2;
      canvas.drawLine(
        Offset(cx + (r - 7) * cos(a), cy + (r - 7) * sin(a)),
        Offset(cx + r * cos(a), cy + r * sin(a)),
        p..strokeWidth = 2.5,
      );
      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(
        cx + (r + 14) * cos(a) - tp.width / 2,
        cy + (r + 14) * sin(a) - tp.height / 2,
      ));
    }
    // Zenith indicator (top = north = up)
    canvas.drawCircle(Offset(cx, cy - r + 6), 4, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.green);
  }

  void _drawCircles(Canvas canvas, Size size, double cx, double cy) {
    final p = Paint()..color = Colors.yellow.withOpacity(0.75)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (final f in [0.12, 0.22, 0.36]) {
      canvas.drawCircle(Offset(cx, cy), size.width * f, p);
    }
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = Colors.yellow);
  }

  void _drawDot(Canvas canvas, double cx, double cy) {
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(cx, cy), 6,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_ZenithPainter old) =>
      old.settings.showZenith != settings.showZenith ||
      old.settings.showGrid != settings.showGrid ||
      old.settings.showCrosshair != settings.showCrosshair ||
      old.settings.zenithStyle != settings.zenithStyle;
}
