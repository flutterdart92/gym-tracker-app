import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
