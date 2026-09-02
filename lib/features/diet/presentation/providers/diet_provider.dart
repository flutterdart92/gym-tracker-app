import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/hive_service.dart';
import '../../data/models/meal_model.dart';

class DietProvider extends ChangeNotifier {
  final Box<MealModel> _mealBox = Hive.box<MealModel>(HiveService.mealBoxName);

  List<MealModel> get meals => _mealBox.values.toList();

  int get totalCalories =>
      _mealBox.values.fold(0, (sum, meal) => sum + meal.calories);

  Future<void> addMeal(MealModel meal) async {
    await _mealBox.put(meal.id, meal);
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    await _mealBox.delete(id);
    notifyListeners();
  }
}
