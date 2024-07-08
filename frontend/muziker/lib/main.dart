import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_manager.dart';
import 'login.dart';
import 'home.dart';
import 'register.dart';
import 'user_login.dart';
import 'settings_provider.dart';
import 'generation_settings.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  ThemeManager themeManager = await ThemeManager.loadPreferences();
  runApp(MyApp(themeManager: themeManager));
}

class MyApp extends StatelessWidget {
  final ThemeManager themeManager;

  MyApp({required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>(create: (_) => themeManager),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(GenerationSettings(
            guidanceScale: 3,
            maxNewTokens: 250,
            doSample: true,
            temperature: 0.8,
          )),
        ),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, theme, _) => MaterialApp(
          title: 'My App',
          theme: theme.themeData,
          initialRoute: '/',
          routes: {
            '/': (context) => LoginPage(),
            '/home': (context) => HomePage(),
            '/register': (context) => RegisterPage(),
            '/userlogin': (context) => UserLoginPage(),
          },
        ),
      ),
    );
  }
}
