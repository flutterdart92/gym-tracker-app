import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ProfileProvider extends ChangeNotifier {
  static const String settingsBoxName = 'settings_box';

  ThemeMode _themeMode = ThemeMode.light;
  int _targetCalories = 2000;
  double _targetProtein = 150.0;
  double _targetCarbs = 200.0;
  double _targetFats = 65.0;

  ThemeMode get themeMode => _themeMode;
  int get targetCalories => _targetCalories;
  double get targetProtein => _targetProtein;
  double get targetCarbs => _targetCarbs;
  double get targetFats => _targetFats;

  ProfileProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox(settingsBoxName);
    _targetCalories = box.get('targetCalories', defaultValue: 2000);
    _targetProtein = box.get('targetProtein', defaultValue: 150.0);
    _targetCarbs = box.get('targetCarbs', defaultValue: 200.0);
    _targetFats = box.get('targetFats', defaultValue: 65.0);

    final isDark = box.get('isDarkMode', defaultValue: false);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> updateGoals({
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    _targetCalories = calories;
    _targetProtein = protein;
    _targetCarbs = carbs;
    _targetFats = fats;

    final box = await Hive.openBox(settingsBoxName);
    await box.put('targetCalories', calories);
    await box.put('targetProtein', protein);
    await box.put('targetCarbs', carbs);
    await box.put('targetFats', fats);

    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final box = await Hive.openBox(settingsBoxName);
    await box.put('isDarkMode', isDark);
    notifyListeners();
  }
}
