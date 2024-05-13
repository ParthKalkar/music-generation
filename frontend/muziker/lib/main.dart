import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';
import 'login.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeManager themeManager = await ThemeManager.loadPreferences();
  runApp(MyApp(themeManager: themeManager));
}

class MyApp extends StatelessWidget {
  final ThemeManager themeManager;

  MyApp({required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>(
      create: (_) => themeManager,
      child: Consumer<ThemeManager>(
        builder: (context, theme, _) => MaterialApp(
          title: 'My App',
          theme: theme.themeData,
          initialRoute: '/',
          routes: {
            '/': (context) => LoginPage(),
            '/home': (context) => HomePage(),
          },
        ),
      ),
    );
  }
}
