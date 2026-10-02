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
  final String userId; // Added user association

  ExerciseModel({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.createdAt,
    required this.userId,
  });
}
