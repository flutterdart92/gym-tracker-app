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
  final double weightKg;

  @HiveField(5)
  final DateTime date;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.date,
  });
}
