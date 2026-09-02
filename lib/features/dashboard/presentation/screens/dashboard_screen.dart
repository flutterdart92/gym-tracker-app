import 'package:flutter/material.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:gym_tracker_app/features/diet/data/services/diet_service.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
import 'package:gym_tracker_app/features/workout/data/services/workout_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dietService = DietService();
    final workoutService = WorkoutService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
        builder: (context, Box<MealModel> mealBox, _) {
          return ValueListenableBuilder(
            valueListenable:
                Hive.box<ExerciseModel>(HiveService.exerciseBoxName)
                    .listenable(),
            builder: (context, Box<ExerciseModel> workoutBox, _) {
              final totalCalories = dietService.getTotalCalories();
              final totalProtein = dietService.getTotalProtein();
              final totalCarbs = dietService.getTotalCarbs();
              final totalFats = dietService.getTotalFats();

              final workouts = workoutService.getWorkouts();
              final totalSets =
                  workouts.fold<int>(0, (sum, item) => sum + item.sets);
              final totalExercises = workouts.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nutrition Overview",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Calories Consumed:",
                                    style: TextStyle(fontSize: 16)),
                                Text("$totalCalories kcal",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MacroStat(
                                    label: "Protein",
                                    value:
                                        "${totalProtein.toStringAsFixed(1)}g"),
                                _MacroStat(
                                    label: "Carbs",
                                    value: "${totalCarbs.toStringAsFixed(1)}g"),
                                _MacroStat(
                                    label: "Fats",
                                    value: "${totalFats.toStringAsFixed(1)}g"),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Workout Summary",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MacroStat(
                                label: "Exercises", value: "$totalExercises"),
                            _MacroStat(
                                label: "Total Sets", value: "$totalSets"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;

  const _MacroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
