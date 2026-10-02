import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/features/workout/presentation/providers/workout_provider.dart';
import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';
import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final dietProvider = Provider.of<DietProvider>(context);

    final currentUser = authProvider.currentUser;

    // Calculate metrics strictly for the active user via WorkoutProvider
    final todayWorkouts = workoutProvider.todayWorkouts;
    final totalExercises = todayWorkouts.length;
    final totalSets =
        todayWorkouts.fold<int>(0, (sum, item) => sum + item.sets);

    // Calculate metrics strictly for the active user via DietProvider
    final todayMeals = dietProvider.todayMeals;
    final totalCalories =
        todayMeals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final totalProtein =
        todayMeals.fold<double>(0.0, (sum, meal) => sum + meal.proteinGrams);
    final totalCarbs =
        todayMeals.fold<double>(0.0, (sum, meal) => sum + meal.carbsGrams);
    final totalFats =
        todayMeals.fold<double>(0.0, (sum, meal) => sum + meal.fatGrams);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser != null
            ? 'Daily Summary (${currentUser.name})'
            : 'Daily Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nutrition Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        Text(
                          "$totalCalories kcal",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MacroStat(
                          label: "Protein",
                          value: "${totalProtein.toStringAsFixed(1)}g",
                        ),
                        _MacroStat(
                          label: "Carbs",
                          value: "${totalCarbs.toStringAsFixed(1)}g",
                        ),
                        _MacroStat(
                          label: "Fats",
                          value: "${totalFats.toStringAsFixed(1)}g",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Workout Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroStat(label: "Exercises", value: "$totalExercises"),
                    _MacroStat(label: "Total Sets", value: "$totalSets"),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
