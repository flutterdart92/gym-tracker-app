class NutritionSummary {
  final double eatenCalories;
  final double targetCalories;
  final double eatenProtein;
  final double targetProtein;
  final double eatenCarbs;
  final double targetCarbs;
  final double eatenFats;
  final double targetFats;
  final double burnedCalories;

  const NutritionSummary({
    required this.eatenCalories,
    required this.targetCalories,
    required this.eatenProtein,
    required this.targetProtein,
    required this.eatenCarbs,
    required this.targetCarbs,
    required this.eatenFats,
    required this.targetFats,
    this.burnedCalories = 0,
  });

  int get kcalLeft =>
      (targetCalories - eatenCalories).clamp(0, double.infinity).round();
}

class WorkoutSummary {
  final String nextWorkoutName;
  final int nextWorkoutExerciseCount;
  final double todayVolumeKg;
  final int completedWorkoutsThisWeek;
  final int targetWorkoutsThisWeek;
  final int currentStreakDays;
  final int bestStreakDays;

  const WorkoutSummary({
    required this.nextWorkoutName,
    required this.nextWorkoutExerciseCount,
    required this.todayVolumeKg,
    required this.completedWorkoutsThisWeek,
    required this.targetWorkoutsThisWeek,
    required this.currentStreakDays,
    required this.bestStreakDays,
  });
}
