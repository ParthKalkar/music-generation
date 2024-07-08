import 'package:flutter/material.dart';
import 'package:muziker/theme_manager.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class SettingsPage extends StatelessWidget {
  final bool isOffline;

  const SettingsPage({Key? key, this.isOffline = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme Settings'),
            Switch(
              value: themeManager.isDark,
              onChanged: (value) {
                themeManager.toggleTheme();
              },
            ),
            if (!isOffline) ...[
              const SizedBox(height: 20),
              const Text('Generation Settings'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Guidance Scale'),
                  Text(settings.guidanceScale.toStringAsFixed(1)),
                ],
              ),
              Slider(
                label: 'Guidance Scale',
                min: 1,
                max: 10,
                divisions: 9,
                value: settings.guidanceScale,
                onChanged: (value) {
                  settingsProvider.updateGuidanceScale(value);
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Max New Tokens'),
                  Text(settings.maxNewTokens.toString()),
                ],
              ),
              Slider(
                label: 'Max New Tokens',
                min: 50,
                max: 500,
                divisions: 9,
                value: settings.maxNewTokens.toDouble(),
                onChanged: (value) {
                  settingsProvider.updateMaxNewTokens(value.toInt());
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Do Sample'),
                  Switch(
                    value: settings.doSample,
                    onChanged: (value) {
                      settingsProvider.updateDoSample(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Temperature'),
                  Text(settings.temperature.toStringAsFixed(1)),
                ],
              ),
              Slider(
                label: 'Temperature',
                min: 0.1,
                max: 1.0,
                divisions: 9,
                value: settings.temperature,
                onChanged: (value) {
                  settingsProvider.updateTemperature(value);
                },
              ),
              const SizedBox(height: 20),
              const Text('Number of Words'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (settings.numWords > 1) {
                        settingsProvider.updateNumWords(settings.numWords - 1);
                      }
                    },
                  ),
                  Text(settings.numWords.toString()),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      settingsProvider.updateNumWords(settings.numWords + 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Weight Method'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWeightMethodButton(
                    context,
                    'Logarithmic',
                    settings.weightMethod == 'logarithmic',
                        () => settingsProvider.updateWeightMethod('logarithmic'),
                  ),
                  _buildWeightMethodButton(
                    context,
                    'Exponential',
                    settings.weightMethod == 'exponential',
                        () => settingsProvider.updateWeightMethod('exponential'),
                  ),
                  _buildWeightMethodButton(
                    context,
                    'Balanced',
                    settings.weightMethod == 'balanced',
                        () => settingsProvider.updateWeightMethod('balanced'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeightMethodButton(BuildContext context, String label, bool isSelected, VoidCallback onPressed) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : themeManager.themeData.textTheme.button!.color, backgroundColor: isSelected ? themeManager.themeData.primaryColor : themeManager.themeData.disabledColor,
        elevation: 5,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
