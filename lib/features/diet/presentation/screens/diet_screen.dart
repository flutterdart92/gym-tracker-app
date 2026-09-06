// // import 'package:flutter/material.dart';
// // import 'package:hive_flutter/hive_flutter.dart';
// // import '../../data/models/meal_model.dart';
// // import '../../data/services/diet_service.dart';
// // import '../../../../core/services/hive_service.dart';

// // class DietScreen extends StatefulWidget {
// //   const DietScreen({super.key});

// //   @override
// //   State<DietScreen> createState() => _DietScreenState();
// // }

// // class _DietScreenState extends State<DietScreen> {
// //   final DietService _dietService = DietService();
// //   final _formKey = GlobalKey<FormState>();

// //   final TextEditingController _nameController = TextEditingController();
// //   final TextEditingController _caloriesController = TextEditingController();
// //   final TextEditingController _proteinController = TextEditingController();
// //   final TextEditingController _carbsController = TextEditingController();
// //   final TextEditingController _fatsController = TextEditingController();

// //   void _showAddMealModal(BuildContext context) {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       builder: (ctx) => Padding(
// //         padding: EdgeInsets.only(
// //           bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
// //           top: 16,
// //           left: 16,
// //           right: 16,
// //         ),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               const Text('Add Meal',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //               TextFormField(
// //                 controller: _nameController,
// //                 decoration: const InputDecoration(labelText: 'Meal Name'),
// //                 validator: (val) =>
// //                     val == null || val.isEmpty ? 'Enter name' : null,
// //               ),
// //               Row(
// //                 children: [
// //                   Expanded(
// //                     child: TextFormField(
// //                       controller: _caloriesController,
// //                       decoration:
// //                           const InputDecoration(labelText: 'Calories (kcal)'),
// //                       keyboardType: TextInputType.number,
// //                       validator: (val) =>
// //                           val == null || val.isEmpty ? 'Enter calories' : null,
// //                     ),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Expanded(
// //                     child: TextFormField(
// //                       controller: _proteinController,
// //                       decoration:
// //                           const InputDecoration(labelText: 'Protein (g)'),
// //                       keyboardType: TextInputType.number,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               Row(
// //                 children: [
// //                   Expanded(
// //                     child: TextFormField(
// //                       controller: _carbsController,
// //                       decoration: const InputDecoration(labelText: 'Carbs (g)'),
// //                       keyboardType: TextInputType.number,
// //                     ),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Expanded(
// //                     child: TextFormField(
// //                       controller: _fatsController,
// //                       decoration: const InputDecoration(labelText: 'Fats (g)'),
// //                       keyboardType: TextInputType.number,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 16),
// //               ElevatedButton(
// //                 onPressed: () async {
// //                   if (_formKey.currentState!.validate()) {
// //                     final meal = MealModel(
// //                       id: DateTime.now().millisecondsSinceEpoch.toString(),
// //                       name: _nameController.text,
// //                       calories: int.parse(_caloriesController.text),
// //                       proteinGrams:
// //                           double.tryParse(_proteinController.text) ?? 0.0,
// //                       carbsGrams: double.tryParse(_carbsController.text) ?? 0.0,
// //                       fatGrams: double.tryParse(_fatsController.text) ?? 0.0,
// //                       date: DateTime.now(),
// //                     );
// //                     await _dietService.addMeal(meal);
// //                     _nameController.clear();
// //                     _caloriesController.clear();
// //                     _proteinController.clear();
// //                     _carbsController.clear();
// //                     _fatsController.clear();
// //                     if (context.mounted) Navigator.pop(ctx);
// //                   }
// //                 },
// //                 child: const Text('Save Meal'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Diet Log')),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () => _showAddMealModal(context),
// //         child: const Icon(Icons.add),
// //       ),
// //       body: ValueListenableBuilder(
// //         valueListenable:
// //             Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
// //         builder: (context, Box<MealModel> box, _) {
// //           final meals = box.values.toList();
// //           final totalCalories = _dietService.getTotalCalories();

// //           return Column(
// //             children: [
// //               Card(
// //                 margin: const EdgeInsets.all(16),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(16),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       const Text('Total Calories:',
// //                           style: TextStyle(
// //                               fontSize: 16, fontWeight: FontWeight.bold)),
// //                       Text('$totalCalories kcal',
// //                           style: const TextStyle(
// //                               fontSize: 18,
// //                               color: Colors.blue,
// //                               fontWeight: FontWeight.bold)),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //               Expanded(
// //                 child: meals.isEmpty
// //                     ? const Center(child: Text('No meals logged today.'))
// //                     : ListView.builder(
// //                         itemCount: meals.length,
// //                         itemBuilder: (context, index) {
// //                           final meal = meals[index];
// //                           return ListTile(
// //                             title: Text(meal.name),
// //                             subtitle: Text(
// //                                 '${meal.calories} kcal | P: ${meal.proteinGrams}g | C: ${meal.carbsGrams}g | F: ${meal.fatGrams}g'),
// //                             trailing: IconButton(
// //                               icon: const Icon(Icons.delete, color: Colors.red),
// //                               onPressed: () => _dietService.deleteMeal(index),
// //                             ),
// //                           );
// //                         },
// //                       ),
// //               ),
// //             ],
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// /*

// Update : Here is the updated diet_screen.dart file.

// It passes the required userId parameter when instantiating MealModel and filters the meals list by the active user's ID.

// */

// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:provider/provider.dart';
// import '../../data/models/meal_model.dart';
// import '../../data/services/diet_service.dart';
// import '../../../../core/services/hive_service.dart';
// import '../../../auth/presentation/providers/auth_provider.dart';

// class DietScreen extends StatefulWidget {
//   const DietScreen({super.key});

//   @override
//   State<DietScreen> createState() => _DietScreenState();
// }

// class _DietScreenState extends State<DietScreen> {
//   final DietService _dietService = DietService();
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _caloriesController = TextEditingController();
//   final TextEditingController _proteinController = TextEditingController();
//   final TextEditingController _carbsController = TextEditingController();
//   final TextEditingController _fatsController = TextEditingController();

//   void _showAddMealModal(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//           top: 16,
//           left: 16,
//           right: 16,
//         ),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Add Meal',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Meal Name'),
//                 validator: (val) =>
//                     val == null || val.isEmpty ? 'Enter name' : null,
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _caloriesController,
//                       decoration:
//                           const InputDecoration(labelText: 'Calories (kcal)'),
//                       keyboardType: TextInputType.number,
//                       validator: (val) =>
//                           val == null || val.isEmpty ? 'Enter calories' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _proteinController,
//                       decoration:
//                           const InputDecoration(labelText: 'Protein (g)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _carbsController,
//                       decoration: const InputDecoration(labelText: 'Carbs (g)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _fatsController,
//                       decoration: const InputDecoration(labelText: 'Fats (g)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     final authProvider =
//                         Provider.of<AuthProvider>(context, listen: false);

//                     final meal = MealModel(
//                       id: DateTime.now().millisecondsSinceEpoch.toString(),
//                       name: _nameController.text.trim(),
//                       calories: int.parse(_caloriesController.text.trim()),
//                       proteinGrams:
//                           double.tryParse(_proteinController.text.trim()) ??
//                               0.0,
//                       carbsGrams:
//                           double.tryParse(_carbsController.text.trim()) ?? 0.0,
//                       fatGrams:
//                           double.tryParse(_fatsController.text.trim()) ?? 0.0,
//                       date: DateTime.now(),
//                       userId: authProvider.currentUser?.email ??
//                           '', // Provided required userId
//                     );

//                     await _dietService.addMeal(meal);
//                     _nameController.clear();
//                     _caloriesController.clear();
//                     _proteinController.clear();
//                     _carbsController.clear();
//                     _fatsController.clear();
//                     if (context.mounted) Navigator.pop(ctx);
//                   }
//                 },
//                 child: const Text('Save Meal'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId =
//         Provider.of<AuthProvider>(context).currentUser?.email ?? '';

//     return Scaffold(
//       appBar: AppBar(title: const Text('Diet Log')),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMealModal(context),
//         child: const Icon(Icons.add),
//       ),
//       body: ValueListenableBuilder(
//         valueListenable:
//             Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
//         builder: (context, Box<MealModel> box, _) {
//           // Filter meals to show only the current user's entries
//           final meals =
//               box.values.where((meal) => meal.userId == currentUserId).toList();
//           final totalCalories = _dietService.getTotalCalories();

//           return Column(
//             children: [
//               Card(
//                 margin: const EdgeInsets.all(16),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Total Calories:',
//                           style: TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold)),
//                       Text('$totalCalories kcal',
//                           style: const TextStyle(
//                               fontSize: 18,
//                               color: Colors.blue,
//                               fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: meals.isEmpty
//                     ? const Center(child: Text('No meals logged today.'))
//                     : ListView.builder(
//                         itemCount: meals.length,
//                         itemBuilder: (context, index) {
//                           final meal = meals[index];
//                           return ListTile(
//                             title: Text(meal.name),
//                             subtitle: Text(
//                                 '${meal.calories} kcal | P: ${meal.proteinGrams}g | C: ${meal.carbsGrams}g | F: ${meal.fatGrams}g'),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: () => meal.delete(),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

/* update



Step 2: Fix lib/features/diet/presentation/screens/diet_screen.dart
Update your DietScreen so that deleting and calculating total calories correctly filters by the current user's ID, and make sure meal.delete() or key-based deletion is used:


*/

// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
// import 'package:gym_tracker_app/features/diet/data/services/diet_service.dart';
// import 'package:gym_tracker_app/core/services/hive_service.dart';
// import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';

// class DietScreen extends StatefulWidget {
//   const DietScreen({super.key});

//   @override
//   State<DietScreen> createState() => _DietScreenState();
// }

// class _DietScreenState extends State<DietScreen> {
//   final DietService _dietService = DietService();
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _caloriesController = TextEditingController();
//   final TextEditingController _proteinController = TextEditingController();
//   final TextEditingController _carbsController = TextEditingController();
//   final TextEditingController _fatsController = TextEditingController();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _caloriesController.dispose();
//     _proteinController.dispose();
//     _carbsController.dispose();
//     _fatsController.dispose();
//     super.dispose();
//   }

//   void _showAddMealModal(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//           top: 16,
//           left: 16,
//           right: 16,
//         ),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Add Meal',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Meal Name'),
//                 validator: (val) =>
//                     val == null || val.isEmpty ? 'Enter name' : null,
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _caloriesController,
//                       decoration:
//                           const InputDecoration(labelText: 'Calories (kcal)'),
//                       keyboardType: TextInputType.number,
//                       validator: (val) =>
//                           val == null || val.isEmpty ? 'Enter calories' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _proteinController,
//                       decoration:
//                           const InputDecoration(labelText: 'Protein (g)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _carbsController,
//                       decoration: const InputDecoration(labelText: 'Carbs (g)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _fatsController,
//                       decoration: const InputDecoration(labelText: 'Fats (g)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     try {
//                       final authProvider =
//                           Provider.of<AuthProvider>(context, listen: false);

//                       final userId =
//                           authProvider.currentUser?.email ?? 'guest_user';
//                       print('DEBUG: Saving meal with userId: $userId');

//                       final meal = MealModel(
//                         id: DateTime.now().millisecondsSinceEpoch.toString(),
//                         name: _nameController.text.trim(),
//                         calories: int.parse(_caloriesController.text.trim()),
//                         proteinGrams:
//                             double.tryParse(_proteinController.text.trim()) ??
//                                 0.0,
//                         carbsGrams:
//                             double.tryParse(_carbsController.text.trim()) ??
//                                 0.0,
//                         fatGrams:
//                             double.tryParse(_fatsController.text.trim()) ?? 0.0,
//                         date: DateTime.now(),
//                         userId: userId,
//                       );

//                       await _dietService.addMeal(meal);
//                       print('DEBUG: Meal successfully added to Hive!');

//                       _nameController.clear();
//                       _caloriesController.clear();
//                       _proteinController.clear();
//                       _carbsController.clear();
//                       _fatsController.clear();

//                       if (context.mounted) Navigator.pop(ctx);
//                     } catch (e, stack) {
//                       print('DEBUG ERROR while adding meal: $e');
//                       print(stack);
//                     }
//                   }
//                 },
//                 child: const Text('Save Meal'),
//               )
//               // ElevatedButton(
//               //   onPressed: () async {
//               //     if (_formKey.currentState!.validate()) {
//               //       final authProvider =
//               //           Provider.of<AuthProvider>(context, listen: false);

//               //       final meal = MealModel(
//               //         id: DateTime.now().millisecondsSinceEpoch.toString(),
//               //         name: _nameController.text.trim(),
//               //         calories: int.parse(_caloriesController.text.trim()),
//               //         proteinGrams:
//               //             double.tryParse(_proteinController.text.trim()) ??
//               //                 0.0,
//               //         carbsGrams:
//               //             double.tryParse(_carbsController.text.trim()) ?? 0.0,
//               //         fatGrams:
//               //             double.tryParse(_fatsController.text.trim()) ?? 0.0,
//               //         date: DateTime.now(),
//               //         userId: authProvider.currentUser?.email ?? '',
//               //       );

//               //       await _dietService.addMeal(meal);

//               //       _nameController.clear();
//               //       _caloriesController.clear();
//               //       _proteinController.clear();
//               //       _carbsController.clear();
//               //       _fatsController.clear();

//               //       if (context.mounted) Navigator.pop(ctx);
//               //     }
//               //   },
//               //   child: const Text('Save Meal'),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId =
//         Provider.of<AuthProvider>(context).currentUser?.email ?? '';

//     return Scaffold(
//       appBar: AppBar(title: const Text('Diet Log')),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMealModal(context),
//         child: const Icon(Icons.add),
//       ),
//       body: ValueListenableBuilder(
//         valueListenable:
//             Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
//         builder: (context, Box<MealModel> box, _) {
//           final meals =
//               box.values.where((meal) => meal.userId == currentUserId).toList();

//           final totalCalories =
//               _dietService.getTotalCalories(userId: currentUserId);

//           return Column(
//             children: [
//               Card(
//                 margin: const EdgeInsets.all(16),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Total Calories:',
//                           style: TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold)),
//                       Text('$totalCalories kcal',
//                           style: const TextStyle(
//                               fontSize: 18,
//                               color: Colors.blue,
//                               fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: meals.isEmpty
//                     ? const Center(child: Text('No meals logged today.'))
//                     : ListView.builder(
//                         itemCount: meals.length,
//                         itemBuilder: (context, index) {
//                           final meal = meals[index];
//                           return ListTile(
//                             title: Text(meal.name),
//                             subtitle: Text(
//                                 '${meal.calories} kcal | P: ${meal.proteinGrams}g | C: ${meal.carbsGrams}g | F: ${meal.fatGrams}g'),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: () async {
//                                 await meal.delete();
//                               },
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:gym_tracker_app/features/diet/data/services/diet_service.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final DietService _dietService = DietService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _showAddMealModal(BuildContext outerContext) {
    // Create a local GlobalKey for the form inside this modal instance
    final modalFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: modalFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Meal Name'),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter name' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration:
                          const InputDecoration(labelText: 'Calories (kcal)'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter calories';
                        }
                        if (int.tryParse(val.trim()) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration:
                          const InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatsController,
                      decoration: const InputDecoration(labelText: 'Fats (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  debugPrint('DEBUG: Save Meal Button Clicked');

                  // Ensure form state exists before calling validate()
                  if (modalFormKey.currentState != null &&
                      modalFormKey.currentState!.validate()) {
                    try {
                      final authProvider = Provider.of<AuthProvider>(
                          outerContext,
                          listen: false);

                      final userId =
                          authProvider.currentUser?.email ?? 'guest_user';
                      debugPrint('DEBUG: Saving meal under userId: $userId');

                      final meal = MealModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text.trim(),
                        calories:
                            int.tryParse(_caloriesController.text.trim()) ?? 0,
                        proteinGrams:
                            double.tryParse(_proteinController.text.trim()) ??
                                0.0,
                        carbsGrams:
                            double.tryParse(_carbsController.text.trim()) ??
                                0.0,
                        fatGrams:
                            double.tryParse(_fatsController.text.trim()) ?? 0.0,
                        date: DateTime.now(),
                        userId: userId,
                      );

                      await _dietService.addMeal(meal);
                      debugPrint('DEBUG: Meal saved successfully to Hive!');

                      _nameController.clear();
                      _caloriesController.clear();
                      _proteinController.clear();
                      _carbsController.clear();
                      _fatsController.clear();

                      if (modalContext.mounted) {
                        Navigator.pop(modalContext);
                      }
                    } catch (e, stack) {
                      debugPrint('DEBUG ERROR: Failed to save meal: $e');
                      debugPrint(stack.toString());
                    }
                  } else {
                    debugPrint(
                        'DEBUG: Form validation failed or key was null.');
                  }
                },
                child: const Text('Save Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context).currentUser?.email ?? 'guest_user';

    return Scaffold(
      appBar: AppBar(title: const Text('Diet Log')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealModal(context),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
        builder: (context, Box<MealModel> box, _) {
          final meals =
              box.values.where((meal) => meal.userId == currentUserId).toList();

          final totalCalories =
              _dietService.getTotalCalories(userId: currentUserId);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Calories:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('$totalCalories kcal',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: meals.isEmpty
                    ? const Center(child: Text('No meals logged today.'))
                    : ListView.builder(
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          return ListTile(
                            title: Text(meal.name),
                            subtitle: Text(
                                '${meal.calories} kcal | P: ${meal.proteinGrams}g | C: ${meal.carbsGrams}g | F: ${meal.fatGrams}g'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await meal.delete();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
