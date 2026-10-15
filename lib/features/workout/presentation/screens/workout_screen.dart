import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/hive_service.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workout_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();

  void _deleteExercise(BuildContext context, ExerciseModel exercise) async {
    final deletedExercise = exercise;
    await exercise.delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedExercise.name} deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.yellow,
          onPressed: () async {
            final box = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
            await box.put(deletedExercise.id, deletedExercise);
          },
        ),
      ),
    );
  }

  void _showAddWorkoutModal(
    BuildContext outerContext, {
    ExerciseModel? existingExercise,
  }) {
    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => _ExerciseFormBottomSheet(
        existingExercise: existingExercise,
        outerContext: outerContext,
        workoutService: _workoutService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context).currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add workout',
        onPressed: () => _showAddWorkoutModal(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<ExerciseModel>(HiveService.exerciseBoxName).listenable(),
        builder: (context, Box<ExerciseModel> box, _) {
          final exercises = box.values
              .where((exercise) =>
                  exercise.userId == currentUserId || exercise.userId.isEmpty)
              .toList();

          if (exercises.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fitness_center_rounded,
              title: 'No workouts logged today',
              description:
                  'Keep track of your sets, reps, and weight progression.',
              buttonLabel: 'Log your first workout',
              onPressed: () => _showAddWorkoutModal(context),
            );
          }

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              final setDetails = (exercise.setsList != null &&
                      exercise.setsList!.isNotEmpty)
                  ? exercise.setsList!
                      .map((s) => '${s.weight}kg x ${s.reps} reps')
                      .join(', ')
                  : '${exercise.sets} sets x ${exercise.reps} reps @ ${exercise.weight} kg';

              return Dismissible(
                key: Key(exercise.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteExercise(context, exercise),
                child: ListTile(
                  title: Text(exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(setDetails),
                  onTap: () =>
                      _showAddWorkoutModal(context, existingExercise: exercise),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit exercise',
                        onPressed: () => _showAddWorkoutModal(context,
                            existingExercise: exercise),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete exercise',
                        onPressed: () => _deleteExercise(context, exercise),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseFormBottomSheet extends StatefulWidget {
  final ExerciseModel? existingExercise;
  final BuildContext outerContext;
  final WorkoutService workoutService;

  const _ExerciseFormBottomSheet({
    required this.existingExercise,
    required this.outerContext,
    required this.workoutService,
  });

  @override
  State<_ExerciseFormBottomSheet> createState() =>
      _ExerciseFormBottomSheetState();
}

class _ExerciseFormBottomSheetState extends State<_ExerciseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  late List<SetModel> _sets;
  String _previousSessionText = '-';

  @override
  void initState() {
    super.initState();
    if (widget.existingExercise != null) {
      _nameController.text = widget.existingExercise!.name;
      _sets = (widget.existingExercise!.setsList != null &&
              widget.existingExercise!.setsList!.isNotEmpty)
          ? widget.existingExercise!.setsList!
              .map((s) => SetModel(
                    weight: s.weight,
                    reps: s.reps,
                    rpe: s.rpe,
                    type: s.type,
                    isDone: s.isDone,
                  ))
              .toList()
          : List.generate(
              widget.existingExercise!.sets,
              (_) => SetModel(
                weight: widget.existingExercise!.weight,
                reps: widget.existingExercise!.reps,
              ),
            );
    } else {
      _sets = [SetModel(weight: 0, reps: 0)];
    }
    _fetchPreviousSession();
  }

  void _fetchPreviousSession() {
    final box = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return;

    final previousLogs = box.values.where((e) {
      return e.name.trim().toLowerCase() == name &&
          (widget.existingExercise == null ||
              e.id != widget.existingExercise!.id);
    }).toList();

    if (previousLogs.isNotEmpty) {
      final lastLog = previousLogs.last;
      if (lastLog.setsList != null && lastLog.setsList!.isNotEmpty) {
        setState(() {
          _previousSessionText = lastLog.setsList!
              .map((s) => '${s.weight}kg x ${s.reps} reps')
              .join(', ');
        });
      } else {
        setState(() {
          _previousSessionText = '${lastLog.weight}kg x ${lastLog.reps} reps';
        });
      }
    }
  }

  void _addSet() {
    setState(() {
      final lastWeight = _sets.isNotEmpty ? _sets.last.weight : 0.0;
      final lastReps = _sets.isNotEmpty ? _sets.last.reps : 0;
      _sets.add(SetModel(weight: lastWeight, reps: lastReps));
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
      });
    }
  }

  void _triggerRestTimer() {
    ScaffoldMessenger.of(widget.outerContext).clearSnackBars();
    ScaffoldMessenger.of(widget.outerContext).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.timer, color: Colors.white),
            SizedBox(width: 8),
            Text('Set Completed! 90s Rest Timer Started'),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingExercise == null
                        ? 'Log Exercise'
                        : 'Edit Exercise',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name (e.g., Bench Press)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _fetchPreviousSession(),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter exercise name'
                    : null,
              ),
              if (_previousSessionText != '-') ...[
                const SizedBox(height: 6),
                Text(
                  'Previous: $_previousSessionText',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),

              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.grey.withValues(alpha: 0.1),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 30,
                        child: Text('SET',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(
                        flex: 3,
                        child: Text('KG',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: Text('REPS',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(
                        width: 48,
                        child: Center(
                            child: Text('DONE',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)))),
                  ],
                ),
              ),

              // Per-Set Rows with Validators
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final setItem = _sets[index];
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: setItem.isDone
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade300, width: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              '${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: setItem.weight > 0
                                ? setItem.weight.toString()
                                : '',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}')),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: '0.0',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) =>
                                setItem.weight = double.tryParse(v) ?? 0.0,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(val.trim());
                              if (n == null || n < 0 || n > 500) {
                                return '0–500 kg';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue:
                                setItem.reps > 0 ? setItem.reps.toString() : '',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) =>
                                setItem.reps = int.tryParse(v) ?? 0,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              final n = int.tryParse(val.trim());
                              if (n == null || n < 1 || n > 100) {
                                return '1–100 reps';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: IconButton(
                            icon: Icon(
                              setItem.isDone
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color:
                                  setItem.isDone ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                setItem.isDone = !setItem.isDone;
                              });
                              if (setItem.isDone) {
                                _triggerRestTimer();
                              }
                            },
                          ),
                        ),
                        if (_sets.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: InkWell(
                              onTap: () => _removeSet(index),
                              child: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(
                      widget.outerContext,
                      listen: false,
                    );

                    final topWeight = _sets.fold<double>(
                        0.0, (max, s) => s.weight > max ? s.weight : max);
                    final topReps = _sets.isNotEmpty ? _sets.first.reps : 0;

                    final exercise = ExerciseModel(
                      id: widget.existingExercise?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      sets: _sets.length,
                      reps: topReps,
                      weight: topWeight,
                      createdAt:
                          widget.existingExercise?.createdAt ?? DateTime.now(),
                      userId: widget.existingExercise?.userId ??
                          (authProvider.currentUser?.email ?? ''),
                      setsList: _sets,
                    );

                    final box =
                        Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
                    await box.put(exercise.id, exercise);

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(widget.existingExercise == null
                    ? 'Save Exercise'
                    : 'Update Exercise'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
