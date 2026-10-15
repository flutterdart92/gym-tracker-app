import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:hive/hive.dart';

part 'exercise_model.g.dart';

@HiveType(typeId: 1)
class ExerciseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int sets;

  @HiveField(3)
  final int reps;

  @HiveField(4)
  final double weight;

  @HiveField(5)
  final DateTime? createdAt;

  @HiveField(6)
  final String userId;

  @HiveField(7)
  final List<SetModel>? setsList;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.createdAt,
    required this.userId,
    this.setsList,
  });

  /// Returns true if this exercise achieved a top weight / PR across previous sessions
  bool isPr(Box<ExerciseModel> box) {
    final prevLogs = box.values.where((e) =>
        e.name.trim().toLowerCase() == name.trim().toLowerCase() && e.id != id);
    if (prevLogs.isEmpty) return true; // First time is always a PR!
    final maxPrevWeight =
        prevLogs.fold<double>(0.0, (max, e) => e.weight > max ? e.weight : max);
    return weight > maxPrevWeight;
  }
}
