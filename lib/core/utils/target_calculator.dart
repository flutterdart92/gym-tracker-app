class TargetCalculator {
  /// Calculates total implied calories based on macronutrient values.
  /// Protein: 4 kcal/g | Carbs: 4 kcal/g | Fats: 9 kcal/g
  static int calculateImpliedCalories({
    required double protein,
    required double carbs,
    required double fats,
  }) {
    return ((protein * 4) + (carbs * 4) + (fats * 9)).round();
  }

  /// Parses string inputs safely and returns implied calories.
  static int calculateFromStrings({
    required String proteinStr,
    required String carbsStr,
    required String fatsStr,
  }) {
    final p = double.tryParse(proteinStr.trim()) ?? 0;
    final c = double.tryParse(carbsStr.trim()) ?? 0;
    final f = double.tryParse(fatsStr.trim()) ?? 0;
    return calculateImpliedCalories(protein: p, carbs: c, fats: f);
  }
}