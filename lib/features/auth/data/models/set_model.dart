import 'package:hive/hive.dart';

// part 'set_models.g.dart';

// part 'package:gym_tracker_app/features/auth/data/models/set_models.g.dart';

part 'set_model.g.dart';

@HiveType(typeId: 5)
class SetModel extends HiveObject {
  @HiveField(0)
  double weight;

  @HiveField(1)
  int reps;

  @HiveField(2)
  double? rpe; // Rate of Perceived Exertion (1-10)

  @HiveField(3)
  String type; // 'working', 'warmup', 'drop', 'failure'

  @HiveField(4)
  bool isDone;

  SetModel({
    required this.weight,
    required this.reps,
    this.rpe,
    this.type = 'working',
    this.isDone = false,
  });
}
