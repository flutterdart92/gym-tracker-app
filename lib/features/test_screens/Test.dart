// // ignore_for_file: camel_case_types, library_private_types_in_public_api

// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_scale_tap/flutter_scale_tap.dart';
// // import 'package:flutter_scale_tap/flutter_scale_tap.dart';
// import 'package:gap/gap.dart';
// import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';
// import 'package:gym_tracker_app/features/test_screens/advanced_haptics.dart';
// import 'package:gym_tracker_app/features/test_screens/advanced_shimmer.dart';
// import 'package:gym_tracker_app/features/test_screens/auto_shimmer_animate.dart';
// import 'package:gym_tracker_app/features/test_screens/awesome_dialog.dart';
// import 'package:gym_tracker_app/features/test_screens/bouncy_button.dart';
// import 'package:gym_tracker_app/features/test_screens/buttons/animated_icon_button.dart';
// import 'package:gym_tracker_app/features/test_screens/buttons/on_process_button_widget.dart';
// import 'package:gym_tracker_app/features/test_screens/buttons/scale_button%202.1.2.dart';
// import 'package:gym_tracker_app/features/test_screens/empty_view.dart';
// import 'package:gym_tracker_app/features/test_screens/glowstone.dart';
// import 'package:gym_tracker_app/features/test_screens/haptic_kit.dart';
// import 'package:gym_tracker_app/features/test_screens/m3e_haptics.dart';
// import 'package:gym_tracker_app/features/test_screens/ripplewave1.dart';
// import 'package:gym_tracker_app/features/test_screens/simple_ripple_animation.dart';
// import 'package:gym_tracker_app/features/test_screens/wave_blob.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:ripple_wave/ripple_wave.dart';
// import '../../../../core/services/hive_service.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../auth/presentation/providers/auth_provider.dart';
// import '../../data/models/food_item_model.dart';
// import '../../data/models/meal_model.dart';
// import '../../data/models/meal_type.dart';
// import '../../data/services/diet_service.dart';
// import '../widgets/food_search_sheet.dart';
// import 'barcode_scanner_screen.dart';
// // import 'package:ripple_wave/ripple_wave.dart';

// class DietScreen extends StatefulWidget {
//   const DietScreen({super.key});

//   @override
//   State<DietScreen> createState() => _DietScreenState();
// }

// class _DietScreenState extends State<DietScreen> {
//   final DietService _dietService = DietService();
//   String _selectedFilter = 'Recent';
//   // :-> 30 oct added
//   bool _shouldAnimateList = false;
// // <-: 30 oct added
//   // Tracking variable for the newly added meal ID
//   String? _newlyAddedMealId;

//   // :-> 30 oct added
//   void _triggerTabAnimation() {
//     setState(() => _shouldAnimateList = true);
//     Future.delayed(const Duration(milliseconds: 900), () {
//       if (mounted) setState(() => _shouldAnimateList = false);
//     });
//   }
// // <-: 30 oct added

//   // Controllers for regular meals
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();
//   final TextEditingController _caloriesController = TextEditingController();
//   final TextEditingController _proteinController = TextEditingController();
//   final TextEditingController _carbsController = TextEditingController();
//   final TextEditingController _fatsController = TextEditingController();

//   // Controllers for snacks
//   final TextEditingController _snackNameController = TextEditingController();
//   final TextEditingController _scoopController = TextEditingController();
//   final TextEditingController _snackCaloriesController =
//       TextEditingController();

//   MealType _selectedMealType = MealType.breakfast;

//   final NumberFormat _numberFormatter = NumberFormat.decimalPattern();
//   final DateFormat _timeFormatter = DateFormat.jm();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _quantityController.dispose();
//     _caloriesController.dispose();
//     _proteinController.dispose();
//     _carbsController.dispose();
//     _fatsController.dispose();
//     _snackNameController.dispose();
//     _scoopController.dispose();
//     _snackCaloriesController.dispose();
//     super.dispose();
//   }

//   MealType _getMealType(MealModel meal) {
//     final parts = meal.mealTypeName.split('|');
//     return MealType.values.firstWhere(
//       (e) => e.name == parts[0],
//       orElse: () => MealType.breakfast,
//     );
//   }

//   double _getMealQuantity(MealModel meal) {
//     final parts = meal.mealTypeName.split('|');
//     if (parts.length > 1) {
//       final parsed = double.tryParse(parts[1]);
//       if (parsed != null) {
//         return double.parse(parsed.toStringAsFixed(1));
//       }
//     }
//     final type = _getMealType(meal);
//     if (type == MealType.breakfast) {
//       double qty = meal.fatGrams > 0 ? (meal.fatGrams / 8.0) * 80.0 : 80.0;
//       return double.parse(qty.toStringAsFixed(1));
//     } else if (type == MealType.lunch) {
//       double qty = meal.fatGrams > 0 ? meal.fatGrams / 18.0 : 1.0;
//       return double.parse(qty.toStringAsFixed(1));
//     }
//     return 1.0;
//   }

//   // void _showMealLoggedSuccess(BuildContext context) {
//   void _showMealLoggedSuccess(BuildContext context, String mealId) {
//     // 1. Show the success dialog FIRST (do not set _newlyAddedMealId yet so it doesn't animate behind the dialog)
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.white.withValues(alpha: 1.0),
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (ctx, anim1, anim2) {
//         return Center(
//           child: Material(
//             color: Colors.transparent,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 150,
//                   height: 150,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: const Color.fromARGB(255, 181, 255, 187)
//                         .withValues(alpha: 0.5),
//                   ),
//                   child: Center(
//                     child: Container(
//                       width: 110,
//                       height: 110,
//                       decoration: const BoxDecoration(
//                         color: Color.fromARGB(255, 0, 137, 50),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.check_rounded,
//                         color: Colors.white,
//                         size: 52,
//                       ),
//                     ),
//                   ),
//                 )
//                     .animate()
//                     .scale(
//                       duration: const Duration(milliseconds: 600),
//                       curve: Curves.elasticOut,
//                     )
//                     .fadeIn(duration: const Duration(milliseconds: 300)),
//                 const SizedBox(height: 14),
//                 const Text(
//                   'Meal logged',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                     letterSpacing: 0.3,
//                   ),
//                 ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
//               ],
//             ),
//           ),
//         );
//       },
//       transitionBuilder: (ctx, anim1, anim2, child) {
//         return ScaleTransition(
//           scale: CurvedAnimation(
//             parent: anim1,
//             curve: Curves.elasticOut,
//           ),
//           child: FadeTransition(
//             opacity: anim1,
//             child: child,
//           ),
//         );
//       },
//     );

//     //   Future.delayed(const Duration(milliseconds: 1500), () {
//     //     if (context.mounted) {
//     //       Navigator.of(context, rootNavigator: true).pop();
//     //     }
//     //   });
//     // }
//     Future.delayed(const Duration(milliseconds: 1500), () {
//       if (context.mounted) {
//         Navigator.of(context, rootNavigator: true).pop();

//         // Trigger slide-in animation right as the popup disappears
//         setState(() {
//           _newlyAddedMealId = mealId;
//         });

//         // Clear the new meal ID after animations complete
//         Future.delayed(const Duration(milliseconds: 2500), () {
//           if (mounted && _newlyAddedMealId == mealId) {
//             setState(() {
//               _newlyAddedMealId = null;
//             });
//           }
//         });
//       }
//     });
//   }

//   void _deleteMeal(BuildContext context, MealModel meal) async {
//     final deletedMeal = meal;
//     final messenger = ScaffoldMessenger.of(context);

//     await meal.delete();

//     if (!context.mounted) return;

//     messenger.clearSnackBars();
//     messenger.showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         backgroundColor: AppColors.darkBackground,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 4),
//         content: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 '${deletedMeal.name} deleted',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Colors.white,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             TextButton(
//               onPressed: () async {
//                 final box = Hive.box<MealModel>(HiveService.mealBoxName);
//                 await box.put(deletedMeal.id, deletedMeal);
//                 messenger.hideCurrentSnackBar();
//               },
//               child: const Text(
//                 'UNDO',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Color.fromARGB(255, 187, 250, 94),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _copyYesterdaysMeals(String userId) async {
//     final box = Hive.box<MealModel>(HiveService.mealBoxName);
//     final yesterday = DateTime.now().subtract(const Duration(days: 1));
//     final today = DateTime.now();

//     final yesterdaysMeals = box.values.where((meal) {
//       return meal.userId == userId && _isSameDay(meal.date, yesterday);
//     }).toList();

//     if (yesterdaysMeals.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No meals found from yesterday to copy.')),
//       );
//       return;
//     }

//     for (final meal in yesterdaysMeals) {
//       final copiedMeal = MealModel(
//         id: '${DateTime.now().microsecondsSinceEpoch}_${meal.id}',
//         name: meal.name,
//         calories: meal.calories,
//         proteinGrams: meal.proteinGrams,
//         carbsGrams: meal.carbsGrams,
//         fatGrams: meal.fatGrams,
//         date: today,
//         userId: userId,
//         mealTypeName: meal.mealTypeName,
//       );
//       await _dietService.addMeal(copiedMeal);
//     }

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content:
//               Text('Copied ${yesterdaysMeals.length} meal(s) from yesterday!'),
//         ),
//       );
//     }
//   }

//   void _openFoodSearchSheet(BuildContext context, String userId,
//       {MealType? initialType}) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => FoodSearchSheet(
//         initialMealType: initialType ?? _selectedMealType,
//         userId: userId,
//         onMealSelected: (meal) async {
//           await _dietService.addMeal(meal);
//           if (context.mounted) {
//             // _showMealLoggedSuccess(context);
//             _showMealLoggedSuccess(context, meal.id);
//           }
//         },
//       ),
//     );
//   }

//   void _showPortionDialogForFavorite(FoodItemModel foodItem, String userId) {
//     double servingGrams = 100.0;
//     final servingController = TextEditingController(text: '100');

//     showDialog(
//       context: context,
//       builder: (dialogCtx) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             final double factor = servingGrams / 100.0;
//             final int cal = (foodItem.caloriesPer100g * factor).round();
//             final double p = foodItem.proteinPer100g * factor;
//             final double c = foodItem.carbsPer100g * factor;
//             final double f = foodItem.fatPer100g * factor;

//             return AlertDialog(
//               title: Text(foodItem.name),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (foodItem.brand != null)
//                       Text(
//                         foodItem.brand!,
//                         style: TextStyle(
//                             color: Colors.grey.shade600, fontSize: 13),
//                       ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: servingController,
//                       keyboardType:
//                           const TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [
//                         FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
//                       ],
//                       decoration: const InputDecoration(
//                         labelText: 'Serving Size (g)',
//                         suffixText: 'g',
//                         border: OutlineInputBorder(),
//                       ),
//                       onChanged: (val) {
//                         setDialogState(() {
//                           servingGrams = double.tryParse(val) ?? 100.0;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .surfaceContainerHighest,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _buildNutrientStat('Calories', '$cal kcal'),
//                           _buildNutrientStat(
//                               'Protein', '${_numberFormatter.format(p)}g'),
//                           _buildNutrientStat(
//                               'Carbs', '${_numberFormatter.format(c)}g'),
//                           _buildNutrientStat(
//                               'Fats', '${_numberFormatter.format(f)}g'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogCtx),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final meal = MealModel(
//                       id: DateTime.now().millisecondsSinceEpoch.toString(),
//                       name:
//                           '${foodItem.name} (${servingGrams.toStringAsFixed(0)}g)',
//                       calories: cal,
//                       proteinGrams: double.parse(p.toStringAsFixed(1)),
//                       carbsGrams: double.parse(c.toStringAsFixed(1)),
//                       fatGrams: double.parse(f.toStringAsFixed(1)),
//                       date: DateTime.now(),
//                       userId: userId,
//                       mealTypeName: _selectedMealType.name,
//                     );

//                     await _dietService.addMeal(meal);
//                     if (dialogCtx.mounted) Navigator.pop(dialogCtx);
//                     if (mounted) {
//                       // _showMealLoggedSuccess(context);
//                       _showMealLoggedSuccess(context, meal.id);
//                     }
//                   },
//                   child: const Text('Log Meal'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildNutrientStat(String label, String value) {
//     return Column(
//       children: [
//         Text(label,
//             style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 2),
//         Text(value,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
//       ],
//     );
//   }

//   void _showAddMealModal(BuildContext outerContext,
//       {MealModel? existingMeal, MealType? defaultType}) {
//     final modalFormKey = GlobalKey<FormState>();
//     AutovalidateMode modalAutovalidateMode = AutovalidateMode.disabled;

//     if (existingMeal != null) {
//       _nameController.text = existingMeal.name;
//       final double derivedQty = _getMealQuantity(existingMeal);
//       _quantityController.text = derivedQty == derivedQty.roundToDouble()
//           ? derivedQty.toInt().toString()
//           : derivedQty.toString();
//       _caloriesController.text = existingMeal.calories.toString();
//       _proteinController.text =
//           _numberFormatter.format(existingMeal.proteinGrams);
//       _carbsController.text = _numberFormatter.format(existingMeal.carbsGrams);
//       _fatsController.text = _numberFormatter.format(existingMeal.fatGrams);
//       _selectedMealType = _getMealType(existingMeal);
//     } else {
//       _nameController.text = 'Oatmeal';
//       _quantityController.text = '5';
//       _caloriesController.text = '24';
//       _proteinController.text = '1';
//       _carbsController.text = '4';
//       _fatsController.text = '0.5';
//       _selectedMealType = defaultType ?? MealType.breakfast;
//     }

//     void updateNutrients(String qtyStr) {
//       final qty = double.tryParse(qtyStr.trim()) ?? 0.0;
//       final nameLower = _nameController.text.trim().toLowerCase();

//       if (nameLower.contains('oatmeal') ||
//           _selectedMealType == MealType.breakfast) {
//         final multiplier = qty / 80.0;
//         _caloriesController.text = (380 * multiplier).round().toString();
//         _proteinController.text = (14 * multiplier).toStringAsFixed(0);
//         _carbsController.text = (60 * multiplier).toStringAsFixed(0);
//         _fatsController.text = (8 * multiplier).toStringAsFixed(1);
//       } else {
//         final multiplier = qty;
//         _caloriesController.text = (620 * multiplier).round().toString();
//         _proteinController.text = (45 * multiplier).toStringAsFixed(0);
//         _carbsController.text = (70 * multiplier).toStringAsFixed(0);
//         _fatsController.text = (18 * multiplier).toStringAsFixed(1);
//       }
//     }

//     showModalBottomSheet(
//       context: outerContext,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (modalContext) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             final theme = Theme.of(context);
//             final bool isBreakfast = _selectedMealType == MealType.breakfast;

//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
//                 top: 20,
//                 left: 16,
//                 right: 16,
//               ),
//               child: SingleChildScrollView(
//                 child: Form(
//                   key: modalFormKey,
//                   autovalidateMode: modalAutovalidateMode,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             existingMeal == null ? 'Add Meal' : 'Edit Meal',
//                             style: theme.textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close),
//                             onPressed: () => Navigator.pop(modalContext),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Text('Category',
//                           style: theme.textTheme.labelMedium
//                               ?.copyWith(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 6),
//                       SegmentedButton<MealType>(
//                         segments: MealType.values.map((type) {
//                           return ButtonSegment<MealType>(
//                             value: type,
//                             label: Text(type.displayName,
//                                 style: const TextStyle(fontSize: 10)),
//                             icon: Icon(type.icon, size: 14),
//                           );
//                         }).toList(),
//                         selected: {_selectedMealType},
//                         onSelectionChanged: (Set<MealType> selection) {
//                           setModalState(() {
//                             _selectedMealType = selection.first;
//                             if (_selectedMealType == MealType.breakfast) {
//                               _nameController.text = 'Oatmeal';
//                               _quantityController.text = '5';
//                               updateNutrients('5');
//                             } else if (_selectedMealType == MealType.lunch) {
//                               _nameController.text = 'Chicken Rice Bowl';
//                               _quantityController.text = '1';
//                               updateNutrients('1');
//                             }
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       TextFormField(
//                         controller: _nameController,
//                         decoration: const InputDecoration(
//                           labelText: 'Meal Name',
//                           border: OutlineInputBorder(),
//                         ),
//                         onChanged: (val) {
//                           setModalState(() {
//                             updateNutrients(_quantityController.text);
//                           });
//                         },
//                         validator: (val) => (val == null || val.trim().isEmpty)
//                             ? 'Enter meal name'
//                             : null,
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _quantityController,
//                         decoration: InputDecoration(
//                           labelText:
//                               isBreakfast ? 'Quantity (g)' : 'Quantity (bowls)',
//                           border: const OutlineInputBorder(),
//                         ),
//                         keyboardType: const TextInputType.numberWithOptions(
//                             decimal: true),
//                         inputFormatters: [
//                           FilteringTextInputFormatter.allow(
//                               RegExp(r'^\d*\.?\d{0,2}'))
//                         ],
//                         onChanged: (val) {
//                           setModalState(() {
//                             updateNutrients(val);
//                           });
//                         },
//                         validator: (val) {
//                           if (val == null || val.trim().isEmpty) {
//                             return 'Enter quantity';
//                           }
//                           if ((double.tryParse(val) ?? 0) <= 0) {
//                             return 'Enter valid quantity';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _caloriesController,
//                         decoration: const InputDecoration(
//                           labelText: 'Calories (kcal)',
//                           border: OutlineInputBorder(),
//                         ),
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly
//                         ],
//                         validator: (val) {
//                           if (val == null || val.trim().isEmpty) {
//                             return 'Enter calories';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: _proteinController,
//                               decoration: const InputDecoration(
//                                   labelText: 'Protein (g)',
//                                   border: OutlineInputBorder()),
//                               keyboardType:
//                                   const TextInputType.numberWithOptions(
//                                       decimal: true),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: TextFormField(
//                               controller: _carbsController,
//                               decoration: const InputDecoration(
//                                   labelText: 'Carbs (g)',
//                                   border: OutlineInputBorder()),
//                               keyboardType:
//                                   const TextInputType.numberWithOptions(
//                                       decimal: true),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: TextFormField(
//                               controller: _fatsController,
//                               decoration: const InputDecoration(
//                                   labelText: 'Fats (g)',
//                                   border: OutlineInputBorder()),
//                               keyboardType:
//                                   const TextInputType.numberWithOptions(
//                                       decimal: true),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       _HapticScaleButton(
//                         onPressed: () async {
//                           setModalState(() {
//                             modalAutovalidateMode =
//                                 AutovalidateMode.onUserInteraction;
//                           });

//                           if (modalFormKey.currentState != null &&
//                               modalFormKey.currentState!.validate()) {
//                             final userId = Provider.of<AuthProvider>(
//                                         outerContext,
//                                         listen: false)
//                                     .currentUser
//                                     ?.email ??
//                                 'guest_user';

//                             final enteredQty = double.parse((double.tryParse(
//                                         _quantityController.text.trim()) ??
//                                     1.0)
//                                 .toStringAsFixed(1));
//                             final actualFat =
//                                 double.tryParse(_fatsController.text.trim()) ??
//                                     0.0;

//                             final meal = MealModel(
//                               id: existingMeal?.id ??
//                                   DateTime.now()
//                                       .millisecondsSinceEpoch
//                                       .toString(),
//                               name: _nameController.text.trim(),
//                               calories: int.tryParse(
//                                       _caloriesController.text.trim()) ??
//                                   0,
//                               proteinGrams: double.tryParse(
//                                       _proteinController.text.trim()) ??
//                                   0.0,
//                               carbsGrams: double.tryParse(
//                                       _carbsController.text.trim()) ??
//                                   0.0,
//                               fatGrams: actualFat,
//                               date: existingMeal?.date ?? DateTime.now(),
//                               userId: userId,
//                               mealTypeName:
//                                   '${_selectedMealType.name}|$enteredQty',
//                             );

//                             await _dietService.addMeal(meal);

//                             if (modalContext.mounted) {
//                               Navigator.pop(modalContext);
//                             }
//                             if (outerContext.mounted && existingMeal == null) {
//                               // _showMealLoggedSuccess(outerContext);
//                               _showMealLoggedSuccess(outerContext, meal.id);
//                             }
//                           } else {
//                             HapticFeedback.heavyImpact();
//                           }
//                         },
//                         child: Text(
//                           existingMeal == null ? 'Save' : 'Update Meal',
//                           style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 15,
//                               color: Colors.white),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showAddSnackModal(BuildContext outerContext,
//       {MealModel? existingMeal}) {
//     final modalFormKey = GlobalKey<FormState>();
//     AutovalidateMode modalAutovalidateMode = AutovalidateMode.disabled;

//     if (existingMeal != null) {
//       _snackNameController.text = existingMeal.name;
//       _scoopController.text = existingMeal.proteinGrams > 0
//           ? existingMeal.proteinGrams.toString()
//           : '1';
//       _snackCaloriesController.text = existingMeal.calories.toString();
//       _selectedMealType = _getMealType(existingMeal);
//     } else {
//       _snackNameController.text = 'protein shake';
//       _scoopController.text = '1';
//       _snackCaloriesController.text = '220';
//       _selectedMealType = MealType.snack;
//     }

//     showModalBottomSheet(
//       context: outerContext,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (modalContext) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             final theme = Theme.of(context);

//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
//                 top: 20,
//                 left: 16,
//                 right: 16,
//               ),
//               child: SingleChildScrollView(
//                 child: Form(
//                   key: modalFormKey,
//                   autovalidateMode: modalAutovalidateMode,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             existingMeal == null ? 'Add Snack' : 'Edit Snack',
//                             style: theme.textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.close),
//                             onPressed: () => Navigator.pop(modalContext),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Text('Category',
//                           style: theme.textTheme.labelMedium
//                               ?.copyWith(fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 6),
//                       SegmentedButton<MealType>(
//                         segments: MealType.values.map((type) {
//                           return ButtonSegment<MealType>(
//                             value: type,
//                             label: Text(type.displayName,
//                                 style: const TextStyle(fontSize: 10)),
//                             icon: Icon(type.icon, size: 14),
//                           );
//                         }).toList(),
//                         selected: {_selectedMealType},
//                         onSelectionChanged: (Set<MealType> selection) {
//                           setModalState(() {
//                             _selectedMealType = selection.first;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       TextFormField(
//                         controller: _snackNameController,
//                         decoration: const InputDecoration(
//                           labelText: 'Meal Name',
//                           border: OutlineInputBorder(),
//                         ),
//                         validator: (val) => (val == null || val.trim().isEmpty)
//                             ? 'Enter meal name'
//                             : null,
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _scoopController,
//                         decoration: const InputDecoration(
//                           labelText: 'Scoop',
//                           border: OutlineInputBorder(),
//                         ),
//                         keyboardType: const TextInputType.numberWithOptions(
//                             decimal: true),
//                         inputFormatters: [
//                           FilteringTextInputFormatter.allow(
//                               RegExp(r'^\d*\.?\d{0,1}'))
//                         ],
//                         onChanged: (val) {
//                           final scoops = double.tryParse(val.trim()) ?? 0.0;
//                           final calculatedKcal = (scoops * 220).round();
//                           setModalState(() {
//                             _snackCaloriesController.text =
//                                 calculatedKcal.toString();
//                           });
//                         },
//                         validator: (val) {
//                           if (val == null || val.trim().isEmpty) {
//                             return 'Enter scoop amount';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: _snackCaloriesController,
//                         decoration: const InputDecoration(
//                           labelText: 'Calories (kcal)',
//                           border: OutlineInputBorder(),
//                         ),
//                         keyboardType: TextInputType.number,
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       _HapticScaleButton(
//                         onPressed: () async {
//                           setModalState(() {
//                             modalAutovalidateMode =
//                                 AutovalidateMode.onUserInteraction;
//                           });

//                           if (modalFormKey.currentState != null &&
//                               modalFormKey.currentState!.validate()) {
//                             final userId = Provider.of<AuthProvider>(
//                                         outerContext,
//                                         listen: false)
//                                     .currentUser
//                                     ?.email ??
//                                 'guest_user';

//                             final scoopVal =
//                                 double.tryParse(_scoopController.text.trim()) ??
//                                     1.0;

//                             final meal = MealModel(
//                               id: existingMeal?.id ??
//                                   DateTime.now()
//                                       .millisecondsSinceEpoch
//                                       .toString(),
//                               name: _snackNameController.text.trim(),
//                               calories: int.tryParse(
//                                       _snackCaloriesController.text.trim()) ??
//                                   220,
//                               proteinGrams: scoopVal,
//                               carbsGrams: 0.0,
//                               fatGrams: 0.0,
//                               date: existingMeal?.date ?? DateTime.now(),
//                               userId: userId,
//                               mealTypeName: _selectedMealType.name,
//                             );

//                             await _dietService.addMeal(meal);

//                             if (modalContext.mounted) {
//                               Navigator.pop(modalContext);
//                             }
//                             if (outerContext.mounted && existingMeal == null) {
//                               // _showMealLoggedSuccess(outerContext);
//                               _showMealLoggedSuccess(outerContext, meal.id);
//                             }
//                           } else {
//                             HapticFeedback.heavyImpact();
//                           }
//                         },
//                         child: Text(
//                           existingMeal == null ? 'Save Snack' : 'Update Snack',
//                           style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 15,
//                               color: Colors.white),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   bool _isSameDay(DateTime d1, DateTime d2) {
//     return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId =
//         Provider.of<AuthProvider>(context).currentUser?.email ?? 'guest_user';
//     final today = DateTime.now();
//     final dietProvider = context.watch<DietProvider>();
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     const orderedMealTypes = [
//       MealType.breakfast,
//       MealType.lunch,
//       MealType.snack,
//       MealType.dinner,
//     ];

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
//       appBar: AppBar(
//         title: Text('Diet',
//             style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : AppColors.textDark,
//                 fontSize: 26)),
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         elevation: 0,
//         actions: [
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//             decoration: BoxDecoration(
//               color: isDark ? const Color(0xFF2C2C2C) : AppColors.lightCardBg,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(
//                   color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
//             ),
//             child: const Row(
//               children: [
//                 Icon(Icons.chevron_left,
//                     size: 16, color: AppColors.indigoPrimary),
//                 SizedBox(width: 2),
//                 Text('Today',
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                         color: AppColors.indigoPrimary)),
//                 SizedBox(width: 2),
//                 Icon(Icons.chevron_right,
//                     size: 16, color: AppColors.indigoPrimary),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: ValueListenableBuilder(
//         valueListenable:
//             Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
//         builder: (context, Box<MealModel> mealBox, _) {
//           final todayMeals = mealBox.values.where((meal) {
//             return meal.userId == currentUserId && _isSameDay(meal.date, today);
//           }).toList();

//           final Map<MealType, List<MealModel>> groupedMeals = {
//             for (var type in MealType.values) type: [],
//           };

//           for (var meal in todayMeals) {
//             groupedMeals[_getMealType(meal)]?.add(meal);
//           }

//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 1. Search bar
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                           color: isDark
//                               ? Colors.grey.shade800
//                               : Colors.grey.shade200),
//                     ),
//                     child: TextField(
//                       readOnly: true,
//                       onTap: () => _openFoodSearchSheet(context, currentUserId),
//                       decoration: InputDecoration(
//                         hintText: 'Search food or scan barcode',
//                         hintStyle: TextStyle(
//                             color: isDark
//                                 ? Colors.grey.shade400
//                                 : AppColors.textMuted,
//                             fontSize: 11),
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 14, vertical: 14),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.grid_view_rounded,
//                               color: AppColors.indigoPrimary, size: 20),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) => const BarcodeScannerScreen()),
//                             );
//                           },
//                         ),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),

//                 // 2. Filter Chips
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Padding(
//                     padding: const EdgeInsets.only(
//                         left: 16.0, top: 4.0, bottom: 4.0),
//                     child: Row(
//                       children: ['Recent', 'Favorites', 'Copy yesterday']
//                           .map((filter) {
//                         final isSelected = _selectedFilter == filter;
//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8.0),
//                           child: ChoiceChip(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 15, vertical: 0),
//                             labelPadding: EdgeInsets.zero,
//                             materialTapTargetSize:
//                                 MaterialTapTargetSize.shrinkWrap,
//                             label: Text(filter, textAlign: TextAlign.center),
//                             selected: isSelected,
//                             selectedColor: AppColors.indigoPrimary,
//                             backgroundColor: isDark
//                                 ? const Color(0xFF1E1E1E)
//                                 : AppColors.lightCardBg,
//                             showCheckmark: false,
//                             labelStyle: TextStyle(
//                               color: isSelected
//                                   ? Colors.white
//                                   : (isDark
//                                       ? Colors.grey.shade300
//                                       : AppColors.textMuted),
//                               fontWeight: FontWeight.w600,
//                               fontSize: 9,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             // onSelected: (_) {
//                             //   if (filter == 'Copy yesterday') {
//                             //     _copyYesterdaysMeals(currentUserId);
//                             //   } else {
//                             //     setState(() => _selectedFilter = filter);
//                             //   }
//                             // },
//                             // :-> 30 oct added
//                             onSelected: (_) {
//                               if (filter == 'Copy yesterday') {
//                                 _copyYesterdaysMeals(currentUserId);
//                               } else {
//                                 if (_selectedFilter != filter) {
//                                   setState(() => _selectedFilter = filter);
//                                   _triggerTabAnimation(); // <-- triggers slide
//                                 }
//                               }
//                             },
// // <-: 30 oct added
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 5),

//                 // 3. Conditional Content: Favorites Tab vs Recent/Default Meal Groups
//                 if (_selectedFilter == 'Favorites')
//                   ValueListenableBuilder(
//                     valueListenable:
//                         Hive.box<FoodItemModel>(HiveService.recentFoodsBoxName)
//                             .listenable(),
//                     builder: (context, Box<FoodItemModel> foodBox, _) {
//                       final favorites = foodBox.values
//                           .where((item) => item.isFavorite)
//                           .toList();

//                       if (favorites.isEmpty) {
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 32),
//                           child: Center(
//                             child: Column(
//                               children: [
//                                 Icon(Icons.star_outline,
//                                     size: 48,
//                                     color: isDark
//                                         ? Colors.grey.shade600
//                                         : Colors.grey.shade400),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'No favorite foods yet',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 14,
//                                     color: isDark
//                                         ? Colors.white
//                                         : AppColors.textDark,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Star items in Search & Add Food to see them here.',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey.shade500),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }

//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 15.0),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color:
//                                 isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black
//                                     .withValues(alpha: isDark ? 0.3 : 0.05),
//                                 spreadRadius: 1,
//                                 blurRadius: 5,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: ListView.separated(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             itemCount: favorites.length,
//                             separatorBuilder: (context, index) => Divider(
//                               color: isDark
//                                   ? Colors.grey.shade800
//                                   : Colors.grey.shade200,
//                               height: 1,
//                               indent: 16,
//                               endIndent: 16,
//                             ),
//                             itemBuilder: (context, index) {
//                               final item = favorites[index];
//                               return ListTile(
//                                 title: Text(
//                                   item.name,
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.bold,
//                                     color: isDark
//                                         ? Colors.white
//                                         : AppColors.textDark,
//                                   ),
//                                 ),
//                                 subtitle: Text(
//                                   '${item.caloriesPer100g.round()} kcal per 100g',
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.grey.shade500,
//                                   ),
//                                 ),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.star,
//                                           color: Colors.amber, size: 20),
//                                       onPressed: () {
//                                         item.isFavorite = false;
//                                         item.save();
//                                       },
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(Icons.add_circle_outline,
//                                           color: AppColors.indigoPrimary,
//                                           size: 22),
//                                       onPressed: () =>
//                                           _showPortionDialogForFavorite(
//                                               item, currentUserId),
//                                     ),
//                                   ],
//                                 ),
//                                 onTap: () => _showPortionDialogForFavorite(
//                                     item, currentUserId),
//                               );
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   )
//                 else ...[
//                   for (final type in orderedMealTypes) ...[
//                     _buildMealGroupCard(context, type, groupedMeals[type] ?? [],
//                         currentUserId, isDark),
//                     const Gap(14),
//                   ],
//                 ],

//                 const SizedBox(height: 12),

//                 // 4. Water Tracker
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Water',
//                         style: TextStyle(
//                             fontFamily: 'Poppins',
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                             color: isDark ? Colors.white : AppColors.textDark),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(right: 15.0),
//                         child: Row(
//                           children: List.generate(8, (index) {
//                             final isFilled = index < dietProvider.waterGlasses;
//                             return GestureDetector(
//                               onTap: () =>
//                                   dietProvider.setWaterGlasses(index + 1),
//                               child: Container(
//                                 width: 17,
//                                 height: 25,
//                                 margin: const EdgeInsets.only(left: 3),
//                                 decoration: BoxDecoration(
//                                   color: isFilled
//                                       ? const Color.fromARGB(255, 105, 210, 255)
//                                       : Colors.transparent,
//                                   borderRadius: const BorderRadius.only(
//                                     topLeft: Radius.elliptical(2, 2),
//                                     topRight: Radius.elliptical(2, 2),
//                                     bottomLeft: Radius.elliptical(8, 8),
//                                     bottomRight: Radius.elliptical(8, 8),
//                                   ),
//                                   border: Border.all(
//                                     color: isFilled
//                                         ? const Color.fromARGB(
//                                             255, 105, 210, 255)
//                                         : const Color.fromARGB(
//                                             255, 0, 221, 255),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),

// // Testing

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const awesomedialog()), // <-- your target page
//                       );
//                     },
//                     child: const Text('awesomedialog')),
//                 // const SizedBox(height: 20),
//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const RippleWave(
//                                   child: Icon(Icons.add_ic_call_outlined),
//                                 )), // <-- your target page
//                       );
//                     },
//                     child: const Text('ripple wave')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const ripplewave1()), // <-- your target page
//                       );
//                     },
//                     child: const Text('ripple wave1')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const waveblob()), // <-- your target page
//                       );
//                     },
//                     child: const Text('wave blob')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const glowstone()), // <-- your target page
//                       );
//                     },
//                     child: const Text('glow stone')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const advancedshimmer()), // <-- your target page
//                       );
//                     },
//                     child: const Text('advanced shimmer')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const auto_shimmer_animate()), // <-- your target page
//                       );
//                     },
//                     child: const Text('auto_shimmer_animate')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const empty_view()), // <-- your target page
//                       );
//                     },
//                     child: const Text('empty_view')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const bouncy_button()), // <-- your target page
//                       );
//                     },
//                     child: const Text('bouncy button')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const m3e_haptics()), // <-- your target page
//                       );
//                     },
//                     child: const Text('m3e_haptics')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const animated_icon_button()), // <-- your target page
//                       );
//                     },
//                     child: const Text('animated_icon_button')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const simple_ripple_animation()), // <-- your target page
//                       );
//                     },
//                     child: const Text('simple_ripple_animation ')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const scale_button()), // <-- your target page
//                       );
//                     },
//                     child: const Text('scale_button')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const advanced_haptics()), // <-- your target page
//                       );
//                     },
//                     child: const Text('advanced_haptics')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const VibrationDemoPage()), // <-- your target page
//                       );
//                     },
//                     child: const Text('VibrationDemoPage')),

//                 TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) =>
//                                 const on_process_button_widget()), // <-- your target page
//                       );
//                     },
//                     child: const Text('on_process_button_widget')),

//                 ScaleTap(
//                   onPressed: () {
//                     //Tap
//                   },
//                   onLongPress: () {
//                     //Long press
//                   },
//                   child: Container(
//                     child: const Text("Tap Me"),
//                   ),
//                 ),

//                 // RippleWave(
//                 //   color: Colors.greenAccent,
//                 //   duration: const Duration(milliseconds: 800),
//                 //   repeat: true,
//                 //   childTween: Tween(begin: 0.1, end: 1.0),
//                 //   // animationController: animationController,
//                 //   waveCount: 4,
//                 //   child: const Icon(
//                 //     Icons.done,
//                 //     size: 100,
//                 //     color: Colors.white,
//                 //   ),
//                 // ),

//                 // AppPrimaryButton(
//                 //   label: 'save',
//                 //   onPressed: () {},
//                 // ),
//                 // PressableScale(
//                 //   onPressed: () {},
//                 //   builder: (BuildContext context, bool isPressed) =>
//                 //       const DietScreen(),
//                 //   // builder: (context, isPressed) => ChatListTile(chat: chat),
//                 // )
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildMealGroupCard(BuildContext context, MealType type,
//       List<MealModel> meals, String currentUserId, bool isDark) {
//     final int groupCalories = meals.fold<int>(0, (sum, m) => sum + m.calories);

//     return Padding(
//       padding: const EdgeInsets.only(left: 15.0, right: 15.0),
//       child: Container(
//         clipBehavior: Clip.hardEdge,
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
//               spreadRadius: 1,
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(
//                   left: 14.0, right: 14.0, top: 15, bottom: 5),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     type.displayName,
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                         color: isDark ? Colors.white : AppColors.textDark),
//                   ),
//                   Row(
//                     children: [
//                       Text(
//                         groupCalories > 0 ? '$groupCalories kcal' : '—',
//                         style: const TextStyle(
//                             color: AppColors.textMuted,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12),
//                       ),
//                       const SizedBox(width: 8),
//                       GestureDetector(
//                         onTap: () {
//                           if (type == MealType.snack) {
//                             _showAddSnackModal(context);
//                           } else {
//                             _showAddMealModal(context, defaultType: type);
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: isDark
//                                 ? Colors.grey.shade800
//                                 : const Color(0xFFEEF2FF),
//                           ),
//                           child: const Icon(Icons.add,
//                               size: 18, color: AppColors.indigoPrimary),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             Divider(
//               color: isDark
//                   ? Colors.grey.shade800
//                   : const Color.fromARGB(255, 214, 214, 214),
//               thickness: 1.0,
//               indent: 16.0,
//               endIndent: 16.0,
//             ),

// // Your Breakfast Card

//             // if (meals.isNotEmpty) ...[
//             //   ListView.builder(
//             //     shrinkWrap: true,
//             //     physics: const NeverScrollableScrollPhysics(),
//             //     itemCount: meals.length,
//             //     itemBuilder: (context, index) {
//             //       final meal = meals[index];
//             //       final mealType = _getMealType(meal);
//             //       final bool isSnackItem = mealType == MealType.snack &&
//             //           meal.carbsGrams == 0 &&
//             //           meal.fatGrams == 0;

//             //       final double derivedQty = _getMealQuantity(meal);
//             //       final double cleanDisplayQty =
//             //           double.parse(derivedQty.toStringAsFixed(1));
//             //       final String quantityDisplay = mealType == MealType.breakfast
//             //           ? '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} g'
//             //           : '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} ${cleanDisplayQty == 1 ? 'bowl' : 'bowls'}';

//             //       // // Check if item was added recently (within the last 2 seconds) to trigger the slide-in and glow effect[cite: 2]
//             //       // final bool isRecentlyAdded =
//             //       //     DateTime.now().difference(meal.date).inMilliseconds <
//             //       //         2000;

//             //       final bool isRecentlyAdded = _newlyAddedMealId == meal.id;

//             //       return Dismissible(
//             //         key: Key(meal.id),
//             //         direction: DismissDirection.endToStart,
//             //         background: Container(
//             //           alignment: Alignment.centerRight,
//             //           padding: const EdgeInsets.only(right: 24),
//             //           margin: const EdgeInsets.symmetric(
//             //               horizontal: 8, vertical: 4),
//             //           decoration: BoxDecoration(
//             //             color: Colors.red,
//             //             borderRadius: BorderRadius.circular(16),
//             //           ),
//             //           child: const Text('Delete',
//             //               style: TextStyle(
//             //                   color: Colors.white,
//             //                   fontWeight: FontWeight.bold)),
//             //         ),
//             //         onDismissed: (_) => _deleteMeal(context, meal),
//             //         child: _GlowingMealRow(
//             //           key: ValueKey('${meal.id}_$isRecentlyAdded'),
//             //           isNew: isRecentlyAdded,
//             //           isDark: isDark,
//             //           child: InkWell(
//             //             onTap: () {
//             //               if (isSnackItem) {
//             //                 _showAddSnackModal(context, existingMeal: meal);
//             //               } else {
//             //                 _showAddMealModal(context, existingMeal: meal);
//             //               }
//             //             },
//             //             child: Container(
//             //               margin: const EdgeInsets.symmetric(
//             //                   horizontal: 2, vertical: 4),
//             //               padding: const EdgeInsets.symmetric(
//             //                   horizontal: 12, vertical: 8),
//             //               child: isSnackItem
//             //                   ? Row(
//             //                       mainAxisAlignment:
//             //                           MainAxisAlignment.spaceBetween,
//             //                       crossAxisAlignment: CrossAxisAlignment.center,
//             //                       children: [
//             //                         Column(
//             //                           crossAxisAlignment:
//             //                               CrossAxisAlignment.start,
//             //                           children: [
//             //                             Text(
//             //                               meal.name,
//             //                               style: TextStyle(
//             //                                   fontWeight: FontWeight.bold,
//             //                                   fontSize: 12,
//             //                                   color: isDark
//             //                                       ? Colors.white
//             //                                       : AppColors.textDark),
//             //                             ),
//             //                             const SizedBox(height: 4),
//             //                             Text(
//             //                               '${meal.proteinGrams == meal.proteinGrams.roundToDouble() ? meal.proteinGrams.toInt() : meal.proteinGrams} scoop${meal.proteinGrams == 1 ? '' : 's'}',
//             //                               style: const TextStyle(
//             //                                   color: AppColors.textMuted,
//             //                                   fontSize: 10),
//             //                             ),
//             //                           ],
//             //                         ),
//             //                         Row(
//             //                           children: [
//             //                             ElevatedButton(
//             //                               style: ElevatedButton.styleFrom(
//             //                                 backgroundColor:
//             //                                     const Color(0xFFDC2626),
//             //                                 foregroundColor: Colors.white,
//             //                                 elevation: 0,
//             //                                 padding: const EdgeInsets.symmetric(
//             //                                     horizontal: 16, vertical: 6),
//             //                                 shape: RoundedRectangleBorder(
//             //                                   borderRadius:
//             //                                       BorderRadius.circular(12),
//             //                                 ),
//             //                               ),
//             //                               onPressed: () =>
//             //                                   _deleteMeal(context, meal),
//             //                               child: const Text('Delete',
//             //                                   style: TextStyle(
//             //                                       fontWeight: FontWeight.bold,
//             //                                       fontSize: 11)),
//             //                             ),
//             //                           ],
//             //                         ),
//             //                       ],
//             //                     )
//             //                   : Row(
//             //                       mainAxisAlignment:
//             //                           MainAxisAlignment.spaceBetween,
//             //                       crossAxisAlignment: CrossAxisAlignment.center,
//             //                       children: [
//             //                         Expanded(
//             //                           child: Column(
//             //                             crossAxisAlignment:
//             //                                 CrossAxisAlignment.start,
//             //                             children: [
//             //                               Text(
//             //                                 meal.name,
//             //                                 style: TextStyle(
//             //                                     fontWeight: FontWeight.bold,
//             //                                     fontSize: 12,
//             //                                     color: isDark
//             //                                         ? Colors.white
//             //                                         : AppColors.textDark),
//             //                               ),
//             //                               const SizedBox(height: 4),
//             //                               Text(
//             //                                 '$quantityDisplay • ${_timeFormatter.format(meal.date)}',
//             //                                 style: const TextStyle(
//             //                                     color: AppColors.textMuted,
//             //                                     fontSize: 10),
//             //                               ),
//             //                             ],
//             //                           ),
//             //                         ),
//             //                         _macroChip('${meal.proteinGrams.round()}P',
//             //                             AppColors.proteinIndigo),
//             //                         const SizedBox(width: 6),
//             //                         _macroChip('${meal.carbsGrams.round()}C',
//             //                             AppColors.carbsAmber),
//             //                         const SizedBox(width: 6),
//             //                         _macroChip('${meal.fatGrams.round()}F',
//             //                             AppColors.fatsPink),
//             //                         const SizedBox(width: 5),
//             //                         Text(
//             //                           _numberFormatter.format(meal.calories),
//             //                           style: TextStyle(
//             //                               fontWeight: FontWeight.bold,
//             //                               fontSize: 12,
//             //                               color: isDark
//             //                                   ? Colors.white
//             //                                   : AppColors.textDark),
//             //                         ),
//             //                       ],
//             //                     ),
//             //             ),
//             //           ),
//             //         ),
//             //       );
//             //     },
//             //   ),
//             //   const SizedBox(height: 6),
//             // ],

//             if (meals.isNotEmpty) ...[
//               ClipRect(
//                 // borderRadius: BorderRadius.circular(16),
//                 child: ListView.builder(
//                   clipBehavior: Clip.hardEdge,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   addRepaintBoundaries: true,
//                   itemCount: meals.length,
//                   itemBuilder: (context, index) {
//                     final meal = meals[index];
//                     final mealType = _getMealType(meal);
//                     final bool isSnackItem = mealType == MealType.snack &&
//                         meal.carbsGrams == 0 &&
//                         meal.fatGrams == 0;

//                     final double derivedQty = _getMealQuantity(meal);
//                     final double cleanDisplayQty =
//                         double.parse(derivedQty.toStringAsFixed(1));
//                     final String quantityDisplay = mealType ==
//                             MealType.breakfast
//                         ? '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} g'
//                         : '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} ${cleanDisplayQty == 1 ? 'bowl' : 'bowls'}';

//                     // // Check if item was added recently (within the last 2 seconds) to trigger the slide-in and glow effect[cite: 2]
//                     // final bool isRecentlyAdded =
//                     //     DateTime.now().difference(meal.date).inMilliseconds <
//                     //         2000;

//                     final bool isRecentlyAdded = _newlyAddedMealId == meal.id;

//                     return Dismissible(
//                       key: Key(meal.id),
//                       direction:
//                           DismissDirection.endToStart, // swipe right -> left
//                       // if you want left -> right use: DismissDirection.startToEnd
//                       background: Container(
//                         alignment: Alignment.centerRight,
//                         padding: const EdgeInsets.only(right: 24),
//                         // margin: const EdgeInsets.symmetric(
//                         //     horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: const Text('Delete',
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold)),
//                       ),
//                       onDismissed: (_) => _deleteMeal(context, meal),
//                       child: _GlowingMealRow(
//                         key: ValueKey('${meal.id}_$isRecentlyAdded'),
//                         // :-> 30 oct added
//                         // key: ValueKey(meal.id),
// // <-: 30 oct added
//                         isNew: isRecentlyAdded,

//                         // :-> 30 oct added
//                         forceSlide: _shouldAnimateList,
// // <-: 30 oct added
//                         isDark: isDark,
//                         child: InkWell(
//                           onTap: () {
//                             if (isSnackItem) {
//                               _showAddSnackModal(context, existingMeal: meal);
//                             } else {
//                               _showAddMealModal(context, existingMeal: meal);
//                             }
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.symmetric(
//                                 horizontal: 2, vertical: 4),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 8),
//                             child: isSnackItem
//                                 ? Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     children: [
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             meal.name,
//                                             style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 12,
//                                                 color: isDark
//                                                     ? Colors.white
//                                                     : AppColors.textDark),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Text(
//                                             '${meal.proteinGrams == meal.proteinGrams.roundToDouble() ? meal.proteinGrams.toInt() : meal.proteinGrams} scoop${meal.proteinGrams == 1 ? '' : 's'}',
//                                             style: const TextStyle(
//                                                 color: AppColors.textMuted,
//                                                 fontSize: 10),
//                                           ),
//                                         ],
//                                       ),
//                                       Row(
//                                         children: [
//                                           ElevatedButton(
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor:
//                                                   const Color(0xFFDC2626),
//                                               foregroundColor: Colors.white,
//                                               elevation: 0,
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 16,
//                                                       vertical: 6),
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                             ),
//                                             onPressed: () =>
//                                                 _deleteMeal(context, meal),
//                                             child: const Text('Delete',
//                                                 style: TextStyle(
//                                                     fontWeight: FontWeight.bold,
//                                                     fontSize: 11)),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   )
//                                 : Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     children: [
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               meal.name,
//                                               style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 12,
//                                                   color: isDark
//                                                       ? Colors.white
//                                                       : AppColors.textDark),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               '$quantityDisplay • ${_timeFormatter.format(meal.date)}',
//                                               style: const TextStyle(
//                                                   color: AppColors.textMuted,
//                                                   fontSize: 10),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       _macroChip(
//                                           '${meal.proteinGrams.round()}P',
//                                           AppColors.proteinIndigo),
//                                       const SizedBox(width: 6),
//                                       _macroChip('${meal.carbsGrams.round()}C',
//                                           AppColors.carbsAmber),
//                                       const SizedBox(width: 6),
//                                       _macroChip('${meal.fatGrams.round()}F',
//                                           AppColors.fatsPink),
//                                       const SizedBox(width: 5),
//                                       Text(
//                                         _numberFormatter.format(meal.calories),
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 12,
//                                             color: isDark
//                                                 ? Colors.white
//                                                 : AppColors.textDark),
//                                       ),
//                                     ],
//                                   ),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 6),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _macroChip(String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.20),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//             color: color.withValues(alpha: 1),
//             fontSize: 7,
//             fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }

// /// Visual Update #3: Glowing Meal Row with slide-in & single-pulse lime glow[cite: 2]
// class _GlowingMealRow extends StatefulWidget {
//   final Widget child;
//   final bool isNew;
//   // :-> 30 oct added
//   final bool forceSlide;
// // <-: 30 oct added

//   final bool isDark;

//   const _GlowingMealRow({
//     //Newly added
//     super.key,
//     required this.child,
//     required this.isNew,
//     required this.isDark,

//     // :-> 30 oct added
//     required this.forceSlide,
// // <-: 30 oct added
//   });

//   @override
//   State<_GlowingMealRow> createState() => _GlowingMealRowState();
// }

// class _GlowingMealRowState extends State<_GlowingMealRow> {
//   // late bool _glowing;
//   bool _glowActive = false;

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _glowing = widget.isNew;
//   //   if (_glowing) {
//   //     Future.delayed(const Duration(milliseconds: 1200), () {
//   //       if (mounted) setState(() => _glowing = false);
//   //     });
//   //   }
//   // }

//   @override
//   void initState() {
//     super.initState();
//     if (widget.isNew) {
//       // Wait for slide-in animation to complete (800ms) before turning on the green glow highlight
//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted) {
//           setState(() {
//             _glowActive = true;
//           });

//           // Keep glow active for 1200ms, then fade it out
//           Future.delayed(const Duration(milliseconds: 1200), () {
//             if (mounted) {
//               setState(() {
//                 _glowActive = false;
//               });
//             }
//           });
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 5000),
//       curve: Curves.easeOut,
//       decoration: BoxDecoration(
//         // color: _glowing ? const Color(0xFFECFDF5) : Colors.transparent,
//         // color: _glowing
//         color: _glowActive
//             ? const Color.fromARGB(255, 208, 252, 144)
//             : const Color.fromARGB(255, 253, 253, 253),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           // color: _glowing
//           color: _glowActive
//               ? const Color.fromARGB(255, 153, 255, 0)
//               : Colors.transparent,
//           // color: _glowing
//           // ? const Color.fromARGB(255, 153, 255, 0)
//           // : const Color.fromARGB(255, 127, 211, 0),
//           // width: _glowing ? 5.0 : 0.0,
//           width: _glowActive ? 5.0 : 0.0,
//         ),
//         // boxShadow: _glowing
//         boxShadow: _glowActive
//             ? [
//                 BoxShadow(
//                   color: const Color.fromARGB(255, 188, 238, 114)
//                       .withValues(alpha: 0.3),
//                   blurRadius: 10,
//                   spreadRadius: 1,
//                 ),
//               ]
//             : [],
//       ),
//       child: widget.child,
//     )
//         .animate()
//         .slideX(
//           begin: 0.20,
//           end: 0.0,
//           duration: const Duration(milliseconds: 1600),
//           curve: Curves.easeOutCubic,
//         )
//         .fadeIn(duration: const Duration(milliseconds: 1200));
//   }
// }

// // Storyboard A: Save Button with width/height animation and opposing outer/inner scale
// class _HapticScaleButton extends StatefulWidget {
//   final VoidCallback onPressed;
//   final Widget child;

//   const _HapticScaleButton({
//     required this.onPressed,
//     required this.child,
//   });

//   @override
//   State<_HapticScaleButton> createState() => _HapticScaleButtonState();
// }

// class _HapticScaleButtonState extends State<_HapticScaleButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _innerScaleAnimation;
//   late Animation<double> _outerScaleAnimation;
//   bool _isPressed = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 120),
//     );

//     _innerScaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
//     );

//     _outerScaleAnimation = Tween<double>(begin: 0.98, end: 1.05).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _onPointerDown(PointerDownEvent event) {
//     HapticFeedback.lightImpact();
//     setState(() => _isPressed = true);
//     _controller.forward();
//   }

//   void _onPointerUp(PointerUpEvent event) {
//     setState(() => _isPressed = false);
//     _controller.reverse();
//     widget.onPressed();
//   }

//   void _onPointerCancel(PointerCancelEvent event) {
//     setState(() => _isPressed = false);
//     _controller.reverse();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Listener(
//       onPointerDown: _onPointerDown,
//       onPointerUp: _onPointerUp,
//       onPointerCancel: _onPointerCancel,
//       child: SizedBox(
//         width: double.infinity,
//         height: 58,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             AnimatedBuilder(
//               animation: _outerScaleAnimation,
//               builder: (context, child) {
//                 return Transform.scale(
//                   scale: _outerScaleAnimation.value,
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 120),
//                     curve: Curves.easeOutCubic,
//                     width: _isPressed ? 180 : 200,
//                     height: _isPressed ? 60 : 50,
//                     decoration: BoxDecoration(
//                       color: _isPressed
//                           ? const Color.fromARGB(255, 206, 211, 255)
//                           : const Color.fromARGB(255, 255, 255, 255),
//                       borderRadius: BorderRadius.circular(_isPressed ? 30 : 28),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             AnimatedBuilder(
//               animation: _innerScaleAnimation,
//               builder: (context, child) {
//                 return Transform.scale(
//                   scale: _innerScaleAnimation.value,
//                   child: child,
//                 );
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 120),
//                 curve: Curves.easeOutCubic,
//                 width: _isPressed ? 180 : 200,
//                 height: _isPressed ? 46 : 50,
//                 child: Material(
//                   color: _isPressed
//                       ? const Color(0xFF4338CA)
//                       : AppColors.indigoPrimary,
//                   borderRadius: BorderRadius.circular(24),
//                   clipBehavior: Clip.antiAlias,
//                   child: Center(child: widget.child),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
