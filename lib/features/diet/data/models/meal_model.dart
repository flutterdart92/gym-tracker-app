import 'package:hive/hive.dart';
import 'meal_type.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 2)
class MealModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int calories;

  @HiveField(3)
  final double proteinGrams;

  @HiveField(4)
  final double carbsGrams;

  @HiveField(5)
  final double fatGrams;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String userId;

  @HiveField(8)
  final String mealTypeName;

  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.date,
    required this.userId,
    String? mealTypeName,
  }) : mealTypeName = mealTypeName ?? MealType.snack.name;

  MealType get mealType => MealType.fromString(mealTypeName);
}
