import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';

class DietProvider extends ChangeNotifier {
  List<MealModel> _meals = [];

  bool _isLoading = false;
  int _waterGlasses = 0; // Default to 0 for new profiles
  String? _currentUserId; // Track active user ID

  List<MealModel> get meals => _sourceList;
  bool get isLoading => _isLoading;
  int get waterGlasses => _waterGlasses;

  DietProvider() {
    _initHiveListener();
  }

  Future<void> _initHiveListener() async {
    try {
      final box = await _getMealBox();
      _updateMealsFromBox(box);
      box.listenable().addListener(() {
        _updateMealsFromBox(box);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing meal box listener: $e');
    }
  }

  void _updateMealsFromBox(Box<MealModel> box) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _meals = [];
    } else {
      _meals = box.values
          .where((m) => m.userId == _currentUserId || m.userId.isEmpty)
          .toList();
    }
  }

  /// Helper to get strictly user-filtered source list
  List<MealModel> get _sourceList {
    if (_currentUserId == null) return [];
    if (Hive.isBoxOpen(HiveService.mealBoxName)) {
      return Hive.box<MealModel>(HiveService.mealBoxName)
          .values
          .where((m) => m.userId == _currentUserId || m.userId.isEmpty)
          .toList();
    }
    return _meals;
  }

  Future<int> _loadWaterForUser(String userId) async {
    try {
      if (Hive.isBoxOpen(HiveService.streakBoxName)) {
        final box = Hive.box(HiveService.streakBoxName);
        return box.get('water_$userId', defaultValue: 0) as int;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _saveWaterForUser(int count) async {
    if (_currentUserId == null) return;
    try {
      if (Hive.isBoxOpen(HiveService.streakBoxName)) {
        final box = Hive.box(HiveService.streakBoxName);
        await box.put('water_$_currentUserId', count);
      }
    } catch (_) {}
  }

  void setWaterGlasses(int count) {
    _waterGlasses = count;
    _saveWaterForUser(count);
    notifyListeners();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  /// Get meals logged today, strictly filtered by current user
  List<MealModel> get todayMeals {
    return _sourceList.where((meal) => _isToday(meal.date)).toList();
  }

  /// Get indices (0-6 for Mon-Sun) of days in the current week where meals were logged
  Set<int> get loggedMealDayIndices {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final indices = <int>{};
    for (var m in _sourceList) {
      final localDate = m.date.toLocal();
      if (localDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        indices.add(localDate.weekday - 1);
      }
    }
    return indices;
  }

  double get totalCalories =>
      _sourceList.fold(0.0, (sum, item) => sum + item.calories);

  double get totalProtein =>
      _sourceList.fold(0.0, (sum, item) => sum + item.proteinGrams);

  double get totalCarbs =>
      _sourceList.fold(0.0, (sum, item) => sum + item.carbsGrams);

  double get totalFats =>
      _sourceList.fold(0.0, (sum, item) => sum + item.fatGrams);

  // int get totalCaloriesToday {
  //   return todayMeals.fold(0, (sum, item) => sum + item.calories.round());
  // }

  // double get totalProteinToday {
  //   return todayMeals.fold(0.0, (sum, item) => sum + item.proteinGrams);
  // }

  // double get totalCarbsToday {
  //   return todayMeals.fold(0.0, (sum, item) => sum + item.carbsGrams);
  // }

  // double get totalFatsToday {
  //   return todayMeals.fold(0.0, (sum, item) => sum + item.fatGrams);
  // }
  int get totalCaloriesToday {
    return _sourceList.fold(0, (sum, item) => sum + item.calories.round());
  }

  double get totalProteinToday {
    return _sourceList.fold(0.0, (sum, item) => sum + item.proteinGrams);
  }

  double get totalCarbsToday {
    return _sourceList.fold(0.0, (sum, item) => sum + item.carbsGrams);
  }

  double get totalFatsToday {
    return _sourceList.fold(0.0, (sum, item) => sum + item.fatGrams);
  }

  Future<Box<MealModel>> _getMealBox() async {
    if (Hive.isBoxOpen(HiveService.mealBoxName)) {
      return Hive.box<MealModel>(HiveService.mealBoxName);
    }
    return await Hive.openBox<MealModel>(
      HiveService.mealBoxName,
      encryptionCipher: HiveService.cipher,
    );
  }

  Future<void> loadUserMeals(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();
    try {
      final box = await _getMealBox();
      _meals = box.values.where((meal) {
        return meal.userId == userId || meal.userId.isEmpty;
      }).toList();

      // Load user-specific water glasses
      _waterGlasses = await _loadWaterForUser(userId);
    } catch (e) {
      debugPrint('Error loading meals from Hive: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(MealModel meal) async {
    try {
      final box = await _getMealBox();
      await box.add(meal);
      if (!_meals.contains(meal)) {
        _meals.add(meal);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding meal to Hive: $e');
    }
  }

  Future<void> deleteMeal(MealModel meal) async {
    try {
      final box = await _getMealBox();
      final keyToDelete = box.keys.firstWhere(
        (key) => box.get(key) == meal,
        orElse: () => null,
      );

      if (keyToDelete != null) {
        await box.delete(keyToDelete);
      } else {
        final keyByMatch = box.keys.firstWhere(
          (key) {
            final item = box.get(key);
            return item?.name == meal.name && item?.date == meal.date;
          },
          orElse: () => null,
        );
        if (keyByMatch != null) {
          await box.delete(keyByMatch);
        }
      }

      _meals.removeWhere((item) =>
          item == meal || (item.name == meal.name && item.date == meal.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting meal from Hive: $e');
    }
  }

  Future<void> clearAllMeals() async {
    try {
      final box = await _getMealBox();
      final keysToDelete = box.keys.where((key) {
        final meal = box.get(key);
        return meal != null && meal.userId == _currentUserId;
      }).toList();
      await box.deleteAll(keysToDelete);
      _meals.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing meal box: $e');
    }
  }

  void resetState() {
    _currentUserId = null;
    _meals.clear();
    _waterGlasses = 0; // Reset water on logout/switch
    notifyListeners();
  }
}
