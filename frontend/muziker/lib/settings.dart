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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme Settings'),
            Switch(
              value: Provider.of<ThemeManager>(context).isDark,
              onChanged: (value) {
                Provider.of<ThemeManager>(context, listen: false).toggleTheme();
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
            ],
          ],
        ),
      ),
    );
  }
}
