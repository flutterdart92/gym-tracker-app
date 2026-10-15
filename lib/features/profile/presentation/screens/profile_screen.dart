import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  int _calculateImpliedCalories() {
    final p = double.tryParse(_proteinController.text.trim()) ?? 0;
    final c = double.tryParse(_carbsController.text.trim()) ?? 0;
    final f = double.tryParse(_fatsController.text.trim()) ?? 0;
    return ((p * 4) + (c * 4) + (f * 9)).round();
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

  // --- CORRECTED DATA EXPORT FUNCTION ---
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

      // 1. Gather user meals and workouts from Hive
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

      // 2. Write to a temporary file on the device storage
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/gym_tracker_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (!mounted) return;

      // 3. Trigger native file share/save dialog (Allows saving to Files or sharing)
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
        title: const Text('Change Password'),
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
        TextEditingController(text: user.age?.toString() ?? '25');
    final weightController =
        TextEditingController(text: user.weight?.toString() ?? '70');
    final heightController =
        TextEditingController(text: user.height?.toString() ?? '175');

    String selectedGoal = user.fitnessGoal ?? 'Weight Loss';
    final goals = ['Weight Loss', 'Muscle Gain', 'Maintenance'];

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: Form(
                key: editProfileFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Edit Body Stats & Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter age';
                                }
                                final n = int.tryParse(val.trim());
                                if (n == null || n < 10 || n > 120) {
                                  return '10–120';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter weight';
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 20 || n > 300) {
                                  return '20–300 kg';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: heightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Height (cm)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter height';
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 80 || n > 250) {
                                  return '80–250 cm';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: goals.contains(selectedGoal)
                            ? selectedGoal
                            : goals.first,
                        decoration: const InputDecoration(
                          labelText: 'Fitness Goal',
                          border: OutlineInputBorder(),
                        ),
                        items: goals
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedGoal = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () async {
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
                                      Text('Profile updated successfully!'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Update Profile'),
                      ),
                      const SizedBox(height: 12),
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
    final impliedCalories = _calculateImpliedCalories();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: user != null
                    ? () => _showEditProfileModal(context, user)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      user?.name ?? 'User Name',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Icon(Icons.edit,
                                        size: 18, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'No email available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            _StatRow(
                              label: 'Age',
                              value:
                                  user?.age != null ? '${user!.age} yrs' : '--',
                            ),
                            const SizedBox(height: 6),
                            _StatRow(
                              label: 'Weight',
                              value: user?.weight != null
                                  ? '${user!.weight} kg'
                                  : '--',
                            ),
                            const SizedBox(height: 6),
                            _StatRow(
                              label: 'Height',
                              value: user?.height != null
                                  ? '${user!.height} cm'
                                  : '--',
                            ),
                            const SizedBox(height: 6),
                            _StatRow(
                              label: 'Goal',
                              value: user?.fitnessGoal ?? 'Weight Loss',
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.blue),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                value: profile.themeMode == ThemeMode.dark,
                onChanged: (val) => profile.toggleTheme(val),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Daily Nutrition Targets',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Implied from macros: $impliedCalories kcal (4P + 4C + 9F)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _calController,
                        decoration: const InputDecoration(
                          labelText: 'Target Calories (kcal)',
                          hintText: '800–6000',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter target calories';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 800 || n > 6000) {
                            return 'Enter target between 800 and 6000 kcal';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              decoration: const InputDecoration(
                                  labelText: 'Protein (g)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter protein';
                                }
                                final n = double.tryParse(v.trim());
                                if (n == null || n < 0 || n > 500) {
                                  return '0–500 g';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _carbsController,
                              decoration:
                                  const InputDecoration(labelText: 'Carbs (g)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter carbs';
                                }
                                final n = double.tryParse(v.trim());
                                if (n == null || n < 0 || n > 500) {
                                  return '0–500 g';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _fatsController,
                              decoration:
                                  const InputDecoration(labelText: 'Fats (g)'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter fats';
                                }
                                final n = double.tryParse(v.trim());
                                if (n == null || n < 0 || n > 500) {
                                  return '0–500 g';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveGoals,
                        child: const Text('Save Targets'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                      onPressed:
                          _exportUserData, // <--- EXPORT FUNCTION CONNECTED HERE
                      icon: const Icon(Icons.download),
                      label: const Text('Export My Data'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade900,
                        side: BorderSide(color: Colors.orange.shade400),
                      ),
                      onPressed: _showDeleteLogsDialog,
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Delete All Logs'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showDeleteAccountDialog,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Theme.of(context).primaryColor : null,
          ),
        ),
      ],
    );
  }
}
