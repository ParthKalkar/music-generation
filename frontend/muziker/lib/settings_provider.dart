import 'package:flutter/material.dart';
import 'generation_settings.dart';

class SettingsProvider with ChangeNotifier {
  GenerationSettings _settings;

  SettingsProvider(this._settings);

  GenerationSettings get settings => _settings;

  void updateGuidanceScale(double value) {
    _settings.guidanceScale = value;
    notifyListeners();
  }

  void updateMaxNewTokens(int value) {
    _settings.maxNewTokens = value;
    notifyListeners();
  }

  void updateDoSample(bool value) {
    _settings.doSample = value;
    notifyListeners();
  }

  void updateTemperature(double value) {
    _settings.temperature = value;
    notifyListeners();
  }
}
