import 'package:flutter/material.dart';
import 'package:gym_tracker_app/features/auth/data/models/user_model.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
  }

  @override
  void dispose() {
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

// 27 september addition : >

  void _showEditProfileModal(BuildContext outerContext, UserModel user) {
    final nameController = TextEditingController(text: user.name);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: goals.contains(selectedGoal)
                        ? selectedGoal
                        : goals.first,
                    decoration: const InputDecoration(
                      labelText: 'Fitness Goal',
                      border: OutlineInputBorder(),
                    ),
                    items: goals
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedGoal = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;

                      await Provider.of<AuthProvider>(outerContext,
                              listen: false)
                          .updateProfile(
                        name: nameController.text.trim(),
                        fitnessGoal: selectedGoal,
                      );

                      if (modalContext.mounted) {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(outerContext).showSnackBar(
                          const SnackBar(
                              content: Text('Profile updated successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Profile'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

// <: 27 september addition

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Account Details Card

// 27 september addition

            Card(
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: user != null
                    ? () => _showEditProfileModal(context, user)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (user?.fitnessGoal != null) ...[
                              const SizedBox(height: 4),
                              Text('Goal: ${user!.fitnessGoal}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

// 27 september addition

            // Card(
            //   elevation: 2,
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Row(
            //       children: [
            //         CircleAvatar(
            //           radius: 30,
            //           child: Text(
            //             user?.name.isNotEmpty == true
            //                 ? user!.name[0].toUpperCase()
            //                 : 'U',
            //             style: const TextStyle(
            //                 fontSize: 24, fontWeight: FontWeight.bold),
            //           ),
            //         ),
            //         const SizedBox(width: 16),
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 user?.name ?? 'User Name',
            //                 style: const TextStyle(
            //                     fontSize: 18, fontWeight: FontWeight.bold),
            //               ),
            //               const SizedBox(height: 4),
            //               Text(
            //                 user?.email ?? 'No email available',
            //                 style: TextStyle(color: Colors.grey[600]),
            //               ),
            //               if (user?.fitnessGoal != null) ...[
            //                 const SizedBox(height: 4),
            //                 Text('Goal: ${user!.fitnessGoal}'),
            //               ],
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),

            // Theme Switch
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                value: profile.themeMode == ThemeMode.dark,
                onChanged: (val) => profile.toggleTheme(val),
              ),
            ),
            const SizedBox(height: 16),

            // Daily Goals Form
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _calController,
                        decoration: const InputDecoration(
                            labelText: 'Target Calories (kcal)'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter calories' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              decoration: const InputDecoration(
                                  labelText: 'Protein (g)'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _carbsController,
                              decoration:
                                  const InputDecoration(labelText: 'Carbs (g)'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _fatsController,
                              decoration:
                                  const InputDecoration(labelText: 'Fats (g)'),
                              keyboardType: TextInputType.number,
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

            // Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
