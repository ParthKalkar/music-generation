import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Column(
          children: [
            const Text('Theme Settings'),
            Switch(
              value: Provider.of<ThemeManager>(context).isDark,
              onChanged: (value) {
                Provider.of<ThemeManager>(context, listen: false).toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}
