import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workout_service.dart';
import '../../../../core/services/hive_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showAddWorkoutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name (e.g., Bench Press)',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter exercise name' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(labelText: 'Sets'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter sets' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter reps' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter weight' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final exercise = ExerciseModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      sets: int.parse(_setsController.text.trim()),
                      reps: int.parse(_repsController.text.trim()),
                      weightKg: double.parse(_weightController.text.trim()),
                      date: DateTime.now(),
                    );
                    await _workoutService.addWorkout(exercise);
                    _nameController.clear();
                    _setsController.clear();
                    _repsController.clear();
                    _weightController.clear();
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkoutModal(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<ExerciseModel>(HiveService.exerciseBoxName).listenable(),
        builder: (context, Box<ExerciseModel> box, _) {
          final workouts = box.values.toList();

          return workouts.isEmpty
              ? const Center(child: Text('No workouts logged today.'))
              : ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.fitness_center,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        workout.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${workout.sets} sets × ${workout.reps} reps @ ${workout.weightKg} kg',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _workoutService.deleteWorkout(index),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
