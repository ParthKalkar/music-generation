import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'home.dart';

class ThemeManager with ChangeNotifier {
  ThemeData _themeData = darkTheme;
  bool _isDark = false;

  ThemeManager({required bool isDarkMode}) {
    _isDark = isDarkMode;
    _themeData = isDarkMode ? darkTheme : lightTheme;
  }

  ThemeData get themeData => _themeData;

  bool get isDark => _isDark;
  void toggleTheme() {
    _isDark = !_isDark;
    _themeData = _isDark ? darkTheme : lightTheme;
    notifyListeners();
    _savePreferences();
  }

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
  }

  static Future<ThemeManager> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
    return ThemeManager(isDarkMode: isDarkMode);
  }
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF23192C), // deep purple, you can still define it if used directly elsewhere in your app
  scaffoldBackgroundColor: Color(0xFF5A189A), // vivid violet
  colorScheme: ColorScheme.dark(
    shadow:  Colors.black,
    primary: Color(0xFF32095B), // deep purple
    secondary: Color(0xFFEBD2FF), // previously 'accentColor', now 'secondary'
    surface: Color(0xFF9D4EDD), // vivid violet
    onPrimary: Colors.white, // text color on primary
    onSecondary: Color(0xFF23192C), // text color on secondary
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFF9D4EDD)), // soft lavender
      foregroundColor: MaterialStateProperty.all(Colors.white), // text color
    ),
  ),
);


final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF5A189A), // vivid violet, can be used directly in other parts of your app
  scaffoldBackgroundColor: Color(0xFFEBD2FF), // very light purple
  colorScheme: ColorScheme.dark(
    shadow:  Colors.black,
    secondary: Color(0xFF32095B), // deep purple
    primary: Color(0xFFD092FF), // previously 'accentColor', now 'secondary'
    surface: Color(0xFF9D4EDD), // vivid violet
    onSecondary: Colors.white, // text color on primary
    onPrimary: Color(0xFF23192C), // text color on secondary
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFF9D4EDD)), // soft lavender
      foregroundColor: MaterialStateProperty.all(Colors.white), // text color
    ),
  ),
  
);


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
    return MaterialApp(
      title: 'My App',
      theme: themeManager.themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
