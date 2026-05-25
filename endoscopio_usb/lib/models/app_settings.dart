import 'package:flutter/material.dart';

enum ZenithStyle { crosshair, compass, circle, dot }

class AppSettings extends ChangeNotifier {
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _sharpness = 0.0;
  double _zoom = 1.0;
  bool _showZenith = true;
  bool _showGrid = false;
  bool _showCrosshair = true;
  ZenithStyle _zenithStyle = ZenithStyle.crosshair;
  bool _invertColors = false;
  double _whiteBalance = 0.0;

  double get brightness => _brightness;
  double get contrast => _contrast;
  double get sharpness => _sharpness;
  double get zoom => _zoom;
  bool get showZenith => _showZenith;
  bool get showGrid => _showGrid;
  bool get showCrosshair => _showCrosshair;
  ZenithStyle get zenithStyle => _zenithStyle;
  bool get invertColors => _invertColors;
  double get whiteBalance => _whiteBalance;

  void setBrightness(double v) { _brightness = v.clamp(-1.0, 1.0); notifyListeners(); }
  void setContrast(double v) { _contrast = v.clamp(0.5, 2.0); notifyListeners(); }
  void setSharpness(double v) { _sharpness = v.clamp(0.0, 1.0); notifyListeners(); }
  void setZoom(double v) { _zoom = v.clamp(1.0, 4.0); notifyListeners(); }
  void toggleZenith() { _showZenith = !_showZenith; notifyListeners(); }
  void toggleGrid() { _showGrid = !_showGrid; notifyListeners(); }
  void toggleCrosshair() { _showCrosshair = !_showCrosshair; notifyListeners(); }
  void setZenithStyle(ZenithStyle s) { _zenithStyle = s; notifyListeners(); }
  void toggleInvertColors() { _invertColors = !_invertColors; notifyListeners(); }
  void setWhiteBalance(double v) { _whiteBalance = v.clamp(-1.0, 1.0); notifyListeners(); }

  void resetAll() {
    _brightness = 0.0;
    _contrast = 1.0;
    _sharpness = 0.0;
    _zoom = 1.0;
    _showZenith = true;
    _showGrid = false;
    _showCrosshair = true;
    _zenithStyle = ZenithStyle.crosshair;
    _invertColors = false;
    _whiteBalance = 0.0;
    notifyListeners();
  }
}
