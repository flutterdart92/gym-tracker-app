import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? passwordHash;

  @HiveField(4)
  final int? age;

  @HiveField(5)
  final double? weight;

  @HiveField(6)
  final String? fitnessGoal;

  @HiveField(7)
  final double? height;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.passwordHash,
    this.age,
    this.weight,
    this.fitnessGoal,
    this.height,
  });
}
