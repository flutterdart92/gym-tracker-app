// ignore_for_file: curly_braces_in_flow_control_structures, camel_case_types, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_tracker_app/core/theme/app_colors.dart';
import 'package:gym_tracker_app/features/auth/data/models/user_model.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/streak_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _calController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    _calController =
        TextEditingController(text: profile.targetCalories.toString());
    _proteinController =
        TextEditingController(text: profile.targetProtein.toString());
    _carbsController =
        TextEditingController(text: profile.targetCarbs.toString());
    _fatsController =
        TextEditingController(text: profile.targetFats.toString());

    _proteinController.addListener(_onMacroChanged);
    _carbsController.addListener(_onMacroChanged);
    _fatsController.addListener(_onMacroChanged);
  }

  void _onMacroChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _proteinController.removeListener(_onMacroChanged);
    _carbsController.removeListener(_onMacroChanged);
    _fatsController.removeListener(_onMacroChanged);

    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _saveGoals() {
    if (_formKey.currentState!.validate()) {
      Provider.of<ProfileProvider>(context, listen: false).updateGoals(
        calories: int.parse(_calController.text.trim()),
        protein: double.parse(_proteinController.text.trim()),
        carbs: double.parse(_carbsController.text.trim()),
        fats: double.parse(_fatsController.text.trim()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target goals updated!')),
      );
    }
  }

  Future<void> _exportUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active user found to export.')),
        );
        return;
      }

      final mealBox = Hive.box<MealModel>(HiveService.mealBoxName);
      final userMeals = mealBox.values
          .where((m) =>
              m.userId == currentUser.email || m.userId == currentUser.id)
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'calories': m.calories,
                'proteinGrams': m.proteinGrams,
                'carbsGrams': m.carbsGrams,
                'fatGrams': m.fatGrams,
                'date': m.date.toIso8601String(),
                'mealTypeName': m.mealTypeName,
              })
          .toList();

      final exerciseBox = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
      final userExercises = exerciseBox.values
          .where((e) =>
              e.userId == currentUser.email || e.userId == currentUser.id)
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'sets': e.sets,
                'reps': e.reps,
                'weight': e.weight,
                'createdAt': e.createdAt?.toIso8601String(),
                'setsList': e.setsList
                    ?.map((s) => {'weight': s.weight, 'reps': s.reps})
                    .toList(),
              })
          .toList();

      final backupData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userProfile': {
          'name': currentUser.name,
          'email': currentUser.email,
          'age': currentUser.age,
          'weight': currentUser.weight,
          'fitnessGoal': currentUser.fitnessGoal,
        },
        'meals': userMeals,
        'workouts': userExercises,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/gym_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Here is my Gym Tracker backup data file.',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(ctx).pop();
                Provider.of<AuthProvider>(context, listen: false)
                    .logout(context);
              },
              child:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Change Password',
          style: TextStyle(fontSize: 12),
        ),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.trim().length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 6 characters.')),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .changePassword(passController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Password changed successfully!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLogsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Logs?'),
        content: const Text(
          'This will clear all your logged meals and workouts. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .deleteAllLogs(context);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('All logs deleted.')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting logs: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Logs',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final deleteConfirmController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Delete Account',
                style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will permanently delete your account and all associated health & workout data. Type DELETE below to confirm.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: deleteConfirmController,
                    decoration: const InputDecoration(
                      labelText: 'Type "DELETE"',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        canDelete = val.trim() == 'DELETE';
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canDelete ? Colors.red : Colors.grey,
                ),
                onPressed: canDelete
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          Navigator.pop(ctx);
                          await Provider.of<AuthProvider>(context,
                                  listen: false)
                              .deleteAccount(context);
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error deleting account: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                child: const Text('Permanently Delete',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProfileModal(BuildContext outerContext, UserModel user) {
    final editProfileFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final ageController =
        TextEditingController(text: user.age?.toString() ?? '28');
    final weightController =
        TextEditingController(text: user.weight?.toString() ?? '72');
    final heightController =
        TextEditingController(text: user.height?.toString() ?? '178');

    String selectedGoal = user.fitnessGoal ?? 'Muscle Gain';
    final goals = ['Weight Loss', 'Muscle Gain', 'Maintenance'];
    AutovalidateMode modalAutovalidate = AutovalidateMode.disabled;

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;

            InputDecoration fieldDecoration(
                {required String label, String? hint, String? suffix}) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                suffixText: suffix,
                labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                floatingLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indigoPrimary),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF6F7FB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.indigoPrimary, width: 1.2)),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color.fromARGB(255, 19, 19, 19)
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                top: 12,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: editProfileFormKey,
                  autovalidateMode: modalAutovalidate,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              // 'Edit Body Stats & Profile',

                              'Edit Profile',

                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    isDark ? Colors.white : AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : const Color(0xFFF2F3F7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 18,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: fieldDecoration(
                            label: 'Full Name', hint: 'e.g. John Doe'),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              decoration:
                                  fieldDecoration(label: 'Age', hint: '26'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return 'Enter age';
                                final n = int.tryParse(val.trim());
                                if (n == null || n < 10 || n > 120)
                                  return '10-120';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}'))
                              ],
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: fieldDecoration(
                                  label: 'Weight', suffix: 'kg', hint: '55.0'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return 'Enter weight';
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 20 || n > 300)
                                  return '20-300 kg';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: heightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}'))
                              ],
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: fieldDecoration(
                                  label: 'Height', suffix: 'cm', hint: '178'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty)
                                  return 'Enter height';
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 80 || n > 250)
                                  return '80-250 cm';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: goals.contains(selectedGoal)
                            ? selectedGoal
                            : goals.first,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                        dropdownColor:
                            isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        decoration: fieldDecoration(label: 'Fitness Goal'),
                        items: goals
                            .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g,
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedGoal = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      _HapticScaleButton(
                        onPressed: () async {
                          setModalState(() {
                            modalAutovalidate =
                                AutovalidateMode.onUserInteraction;
                          });
                          if (editProfileFormKey.currentState!.validate()) {
                            final ageVal = int.parse(ageController.text.trim());
                            final weightVal =
                                double.parse(weightController.text.trim());
                            final heightVal =
                                double.parse(heightController.text.trim());

                            final messenger =
                                ScaffoldMessenger.of(outerContext);

                            await Provider.of<AuthProvider>(outerContext,
                                    listen: false)
                                .updateProfile(
                              name: nameController.text.trim(),
                              age: ageVal,
                              weight: weightVal,
                              height: heightVal,
                              fitnessGoal: selectedGoal,
                            );

                            final bmr = (10 * weightVal) +
                                (6.25 * heightVal) -
                                (5 * ageVal) +
                                5;
                            final tdee = bmr * 1.375;

                            double calculatedCalories;
                            if (selectedGoal == 'Weight Loss') {
                              calculatedCalories = tdee - 500;
                            } else if (selectedGoal == 'Muscle Gain') {
                              calculatedCalories = tdee + 300;
                            } else {
                              calculatedCalories = tdee;
                            }

                            final targetCals =
                                calculatedCalories.round().clamp(1200, 5000);
                            final targetProt =
                                ((targetCals * 0.30) / 4).roundToDouble();
                            final targetCarb =
                                ((targetCals * 0.45) / 4).roundToDouble();
                            final targetFat =
                                ((targetCals * 0.25) / 9).roundToDouble();

                            final profileProvider =
                                Provider.of<ProfileProvider>(outerContext,
                                    listen: false);
                            await profileProvider.updateGoals(
                              calories: targetCals,
                              protein: targetProt,
                              carbs: targetCarb,
                              fats: targetFat,
                            );

                            _calController.text = targetCals.toString();
                            _proteinController.text = targetProt.toString();
                            _carbsController.text = targetCarb.toString();
                            _fatsController.text = targetFat.toString();

                            if (modalContext.mounted) {
                              Navigator.pop(modalContext);
                              messenger.showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Profile updated successfully!')),
                              );
                            }
                          } else {
                            HapticFeedback.heavyImpact();
                          }
                        },
                        child: const Text('Update Profile',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Live Data Calculations for Step 4
    final currentEmailOrId = user?.email ?? user?.id ?? '';
    final exerciseBox = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);

    final userExercises = exerciseBox.values
        .where((e) => e.userId == currentEmailOrId || e.userId.isEmpty)
        .toList();

    final totalWorkoutsCount = userExercises.length;

    // Calculate PR count dynamically
    final prCount = userExercises.where((e) => e.isPr(exerciseBox)).length;

    // Get live streak from StreakService
    final currentStreak = StreakService.getCurrentStreak();

    // Calculate live TDEE based on user profile stats if available, fallback to profile target calories
    final double userWeight = user?.weight ?? 72.0;
    final double userHeight = user?.height ?? 178.0;
    final int userAge = user?.age ?? 28;
    final calculatedBmr =
        (10 * userWeight) + (6.25 * userHeight) - (5 * userAge) + 5;
    final liveTdee = (calculatedBmr * 1.375).round();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: user != null
                    ? () => _showEditProfileModal(context, user)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.indigoPrimary,
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: const Duration(seconds: 2)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Test User',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'test.user@example.com',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA3E635),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Goal: ${user?.fitnessGoal ?? 'Muscle Gain'}',
                                style: const TextStyle(
                                  color: Color(0xFF365314),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: isDark ? const Color(0xFF0D1117) : Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(
                          value: user?.age != null ? '${user!.age}' : '28',
                          label: 'Age'),
                      _MetricItem(
                          value: user?.weight != null
                              ? '${user!.weight} kg'
                              : '72 kg',
                          label: 'Weight'),
                      _MetricItem(
                          value: user?.height != null
                              ? '${user!.height} cm'
                              : '178 cm',
                          label: 'Height'),
                      _MetricItem(
                          value: liveTdee.toString(),
                          label: 'TDEE'), // Live TDEE Data Binding
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: isDark ? const Color(0xFF0D1117) : Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Workouts',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 8)),
                            const SizedBox(height: 4),
                            Text(totalWorkoutsCount.toString(),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight
                                        .bold)), // Live Workouts Count
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Card(
                      color: isDark ? const Color(0xFF0D1117) : Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRs',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 8)),
                            const SizedBox(height: 4),
                            Text(prCount.toString(),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold)), // Live PR Count
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Card(
                      color: isDark ? const Color(0xFF0D1117) : Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Best streak',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 8)),
                            const SizedBox(height: 4),
                            Text('$currentStreak d',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight
                                        .bold)), // Live Streak Data Binding
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                color: isDark ? const Color(0xFF0D1117) : Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Body weight',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('▲ 0.4 kg / wk',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Replace the SizedBox containing CustomPaint with this:
                      SizedBox(
                        height: 120,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: 65,
                            maxY: 75,
                            lineBarsData: [
                              LineChartBarData(
                                spots: const [
                                  FlSpot(0, 71.0),
                                  FlSpot(1, 71.2),
                                  FlSpot(2, 71.5),
                                  FlSpot(3, 71.8),
                                  FlSpot(4, 72.0),
                                  FlSpot(5, 72.2),
                                  FlSpot(
                                      6, 72.4), // Shows the ▲ 0.4 kg / wk trend
                                ],
                                isCurved: true,
                                color: const Color(0xFFA3E635),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFFA3E635)
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(
                              milliseconds:
                                  600), // Fl_chart animation over 600 ms
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      // SizedBox(
                      //   height: 50,
                      //   child: CustomPaint(
                      //     size: const Size(double.infinity, 50),
                      //     painter: _TrendChartPainter(),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: isDark ? const Color(0xFF0D1117) : Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _SettingRow(
                        title: 'Units', trailing: 'kg / cm', onTap: () {}),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingRow(
                        title: 'Theme',
                        trailing: profile.themeMode == ThemeMode.dark
                            ? 'Dark'
                            : profile.themeMode == ThemeMode.light
                                ? 'Light'
                                : 'System',
                        onTap: () => profile.toggleTheme()),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingRow(
                        title: 'Reminders', trailing: 'On', onTap: () {}),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingRow(
                        title: 'Health Connect',
                        trailing: 'Connected',
                        onTap: () {}),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingRow(
                        title: 'Export my data',
                        trailing: 'CSV',
                        onTap: _exportUserData),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _SettingRow(
                        title: 'Change password',
                        trailing: '',
                        showChevron: true,
                        onTap: _showChangePasswordDialog),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.red.shade200, width: 1.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 17, 0),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Divider(
                        height: 8,
                        color: Color.fromARGB(255, 255, 169, 162),
                        thickness: 2,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Delete all logs',
                                  style: TextStyle(
                                      color: isDark
                                          ? const Color.fromARGB(
                                              255, 19, 19, 19)
                                          : const Color.fromARGB(
                                              255, 19, 19, 19),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                              const SizedBox(height: 2),
                              const Text("Meals and workouts. Can't be undone.",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 117, 52, 52),
                                      fontSize: 8)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            onPressed: _showDeleteLogsDialog,
                            child: const Text('Delete',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 7)),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 8,
                        color: Color.fromARGB(255, 255, 169, 162),
                        thickness: 2,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delete account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: isDark
                                          ? const Color.fromARGB(
                                              255, 19, 19, 19)
                                          : const Color.fromARGB(
                                              255, 19, 19, 19),
                                    )),
                                const SizedBox(height: 2),
                                const Text('Removes the account and all data.',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 117, 52, 52),
                                        fontSize: 8)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            onPressed: _showDeleteAccountDialog,
                            child: const Text('Delete',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  child: Text(
                    'Log out',
                    style: TextStyle(
                      color: isDark
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value;
  final String label;

  const _MetricItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String trailing;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingRow({
    required this.title,
    required this.trailing,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Row(
              children: [
                if (trailing.isNotEmpty)
                  Text(trailing,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA3E635)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.75,
      size.width * 0.6,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.2,
      size.width,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HapticScaleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const _HapticScaleButton({required this.onPressed, required this.child});

  @override
  State<_HapticScaleButton> createState() => _HapticScaleButtonState();
}

class _HapticScaleButtonState extends State<_HapticScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _innerScale;
  late Animation<double> _outerScale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 60));
    _innerScale = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _outerScale = Tween<double>(begin: 0.98, end: 1.05).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent _) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onUp(PointerUpEvent _) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onCancel(PointerCancelEvent _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _outerScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _outerScale.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    width: _isPressed ? 180 : 200,
                    height: _isPressed ? 60 : 50,
                    decoration: BoxDecoration(
                      color: _isPressed
                          ? const Color.fromARGB(255, 206, 211, 255)
                          : const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(_isPressed ? 30 : 28),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _innerScale,
              builder: (context, child) =>
                  Transform.scale(scale: _innerScale.value, child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: _isPressed ? 180 : 200,
                height: _isPressed ? 46 : 50,
                child: Material(
                  color: _isPressed
                      ? const Color(0xFF4F46E5)
                      : AppColors.indigoPrimary,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
