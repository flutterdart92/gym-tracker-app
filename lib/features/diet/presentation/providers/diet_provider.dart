// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import '../../../../core/services/hive_service.dart';
// import '../../data/models/meal_model.dart';

// class DietProvider extends ChangeNotifier {
//   final Box<MealModel> _mealBox = Hive.box<MealModel>(HiveService.mealBoxName);

//   List<MealModel> get meals => _mealBox.values.toList();

//   Future<void> addMeal(MealModel meal) async {
//     await _mealBox.put(meal.id, meal);
//     notifyListeners();
//   }

//   Future<void> deleteMeal(String id) async {
//     await _mealBox.delete(id);
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/meal_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DietProvider extends ChangeNotifier {
  final Box<MealModel> _mealBox = Hive.box<MealModel>('meals_box');
  final AuthProvider authProvider;

  DietProvider(this.authProvider);

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  List<MealModel> get mealsForSelectedDate {
    final currentUserId = authProvider.currentUser?.email ?? '';
    return _mealBox.values.where((meal) {
      return meal.userId == currentUserId &&
          _isSameDay(meal.date, _selectedDate);
    }).toList();
  }

  int get totalCaloriesForSelectedDate {
    return mealsForSelectedDate.fold(0, (sum, meal) => sum + meal.calories);
  }

  double get totalProteinForSelectedDate {
    return mealsForSelectedDate.fold(
        0.0, (sum, meal) => sum + meal.proteinGrams);
  }

  double get totalCarbsForSelectedDate {
    return mealsForSelectedDate.fold(0.0, (sum, meal) => sum + meal.carbsGrams);
  }

  double get totalFatsForSelectedDate {
    return mealsForSelectedDate.fold(0.0, (sum, meal) => sum + meal.fatGrams);
  }

  Future<void> addMeal(MealModel meal) async {
    await _mealBox.add(meal);
    notifyListeners();
  }

  Future<void> deleteMeal(MealModel meal) async {
    await meal.delete();
    notifyListeners();
  }
}
