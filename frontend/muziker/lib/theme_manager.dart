import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  ThemeData _themeData;
  bool _isDark;

  ThemeManager({required bool isDarkMode}) : _isDark = isDarkMode, _themeData = isDarkMode ? darkTheme : lightTheme;

  ThemeData get themeData => _themeData;
  bool get isDark => _isDark;

  void toggleTheme() {
    if (_themeData == darkTheme) {
      _isDark = false;
      _themeData = lightTheme;
    } else if (_themeData == lightTheme) {
      _themeData = colorBlindTheme;
    } else {
      _isDark = true;
      _themeData = darkTheme;
    }
    notifyListeners();
    _savePreferences();
  }

  void setTheme(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        _themeData = darkTheme;
        _isDark = true;
        break;
      case ThemeMode.light:
        _themeData = lightTheme;
        _isDark = false;
        break;
      case ThemeMode.system:
        _themeData = colorBlindTheme;
        _isDark = false;
        break;
    }
    notifyListeners();
    _savePreferences();
  }

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
    await prefs.setString('theme', _themeData == darkTheme ? 'dark' : _themeData == lightTheme ? 'light' : 'colorBlind');
  }

  static Future<ThemeManager> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
    String theme = prefs.getString('theme') ?? 'light';
    ThemeData themeData = theme == 'dark' ? darkTheme : theme == 'light' ? lightTheme : colorBlindTheme;
    return ThemeManager(isDarkMode: isDarkMode).._themeData = themeData;
  }
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF10002B), // deep purple
  scaffoldBackgroundColor: Color(0xFF3C096C), // vivid violet
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF10002B), // deep purple
    secondary: Color(0xFF240046), // dark purple
    background: Color(0xFF3C096C), // vivid violet
    surface: Color(0xFF9D4EDD), // soft lavender
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFF9D4EDD)), // soft lavender
      foregroundColor: MaterialStateProperty.all(Colors.white),
    ),
  ),
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF5A189A), // vivid violet
  scaffoldBackgroundColor: Color(0xFFE0AAFF), // very light purple
  colorScheme: ColorScheme.light(
    primary: Color(0xFF5A189A), // vivid violet
    secondary: Color(0xFF7B2CBF), // soft lavender
    background: Color(0xFFE0AAFF), // very light purple
    surface: Color(0xFFC77DFF), // soft lavender
    onPrimary: Colors.white,
    onSecondary: Colors.black,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFF7B2CBF)), // soft lavender
      foregroundColor: MaterialStateProperty.all(Colors.white),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStateProperty.all(Color(0xFF5A189A)), // vivid violet
    ),
  ),
);

final ThemeData colorBlindTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF006400), // dark green
  scaffoldBackgroundColor: Color(0xFF8FBC8F), // dark sea green
  colorScheme: ColorScheme.light(
    primary: Color(0xFF006400), // dark green
    secondary: Color(0xFF2E8B57), // sea green
    background: Color(0xFF8FBC8F), // dark sea green
    surface: Color(0xFF3CB371), // medium sea green
    onPrimary: Colors.black,
    onSecondary: Colors.black,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFF2E8B57)), // sea green
      foregroundColor: MaterialStateProperty.all(Colors.black),
    ),
  ),
);
