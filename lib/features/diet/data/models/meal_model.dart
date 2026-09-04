import 'package:hive/hive.dart';

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

  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.date,
  });
}
