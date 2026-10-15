import 'package:hive/hive.dart';

part 'food_item_model.g.dart';

@HiveType(typeId: 3)
class FoodItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? brand;

  @HiveField(3)
  final double caloriesPer100g;

  @HiveField(4)
  final double proteinPer100g;

  @HiveField(5)
  final double carbsPer100g;

  @HiveField(6)
  final double fatPer100g;

  @HiveField(7)
  bool isFavorite;

  @HiveField(8)
  final DateTime lastUsed;

  FoodItemModel({
    required this.id,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.isFavorite = false,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  factory FoodItemModel.fromOpenFoodFactsJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    double parseNutrient(List<String> keys) {
      for (final key in keys) {
        if (nutriments.containsKey(key) && nutriments[key] != null) {
          final val = num.tryParse(nutriments[key].toString());
          if (val != null) return val.toDouble();
        }
      }
      return 0.0;
    }

    final energyKcal =
        parseNutrient(['energy-kcal_100g', 'energy-kcal_value', 'energy-kcal']);
    final protein =
        parseNutrient(['proteins_100g', 'proteins_value', 'proteins']);
    final carbs = parseNutrient(
        ['carbohydrates_100g', 'carbohydrates_value', 'carbohydrates']);
    final fat = parseNutrient(['fat_100g', 'fat_value', 'fat']);

    final brandName = json['brands'] as String?;
    final productName = (json['product_name'] as String?)?.trim();

    return FoodItemModel(
      id: json['code']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: productName != null && productName.isNotEmpty
          ? productName
          : 'Unknown Food',
      brand: brandName != null && brandName.isNotEmpty ? brandName : null,
      caloriesPer100g: energyKcal,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
    );
  }
}
