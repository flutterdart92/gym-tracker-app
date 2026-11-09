// ignore_for_file: curly_braces_in_flow_control_structures, camel_case_types, library_private_types_in_public_api

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/food_item_model.dart';
import '../../data/models/meal_model.dart';
import '../../data/models/meal_type.dart';
import '../../data/services/diet_service.dart';
import '../widgets/food_search_sheet.dart';
import 'barcode_scanner_screen.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final DietService _dietService = DietService();
  String _selectedFilter = 'Recent';
  bool _shouldAnimateList = false;
  // bool _isLoading = true;

  // Tracking variable for the newly added meal ID
  String? _newlyAddedMealId;

  void _triggerTabAnimation() {
    setState(() => _shouldAnimateList = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _shouldAnimateList = false);
    });
  }

  // Controllers for regular meals
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();

  // Controllers for snacks
  final TextEditingController _snackNameController = TextEditingController();
  final TextEditingController _scoopController = TextEditingController();
  final TextEditingController _snackCaloriesController =
      TextEditingController();

  MealType _selectedMealType = MealType.breakfast;

  final NumberFormat _numberFormatter = NumberFormat.decimalPattern();
  final DateFormat _timeFormatter = DateFormat.jm();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _snackNameController.dispose();
    _scoopController.dispose();
    _snackCaloriesController.dispose();
    super.dispose();
  }

  MealType _getMealType(MealModel meal) {
    final parts = meal.mealTypeName.split('|');
    return MealType.values.firstWhere(
      (e) => e.name == parts[0],
      orElse: () => MealType.breakfast,
    );
  }

  double _getMealQuantity(MealModel meal) {
    final parts = meal.mealTypeName.split('|');
    if (parts.length > 1) {
      final parsed = double.tryParse(parts[1]);
      if (parsed != null) {
        return double.parse(parsed.toStringAsFixed(1));
      }
    }
    final type = _getMealType(meal);
    if (type == MealType.breakfast) {
      double qty = meal.fatGrams > 0 ? (meal.fatGrams / 8.0) * 80.0 : 80.0;
      return double.parse(qty.toStringAsFixed(1));
    } else if (type == MealType.lunch) {
      double qty = meal.fatGrams > 0 ? meal.fatGrams / 18.0 : 1.0;
      return double.parse(qty.toStringAsFixed(1));
    } else if (type == MealType.dinner) {
      double qty = meal.fatGrams > 0 ? meal.fatGrams / 18.0 : 1.0;
      return double.parse(qty.toStringAsFixed(1));
    }
    return 1.0;
  }

  void _showMealLoggedSuccess(BuildContext context, String mealId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 1.0)
          : Colors.white.withValues(alpha: 1.0),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color.fromARGB(255, 0, 137, 50)
                        : const Color.fromARGB(255, 181, 255, 187)
                            .withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color.fromARGB(255, 127, 255, 138)
                            : const Color.fromARGB(255, 0, 137, 50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: const Duration(milliseconds: 600)),
                const SizedBox(height: 14),
                Text(
                  'Meal logged',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white.withValues(alpha: 1.0)
                        : Colors.black.withValues(alpha: 1.0),
                    letterSpacing: 0.3,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        setState(() {
          _newlyAddedMealId = mealId;
        });

        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted && _newlyAddedMealId == mealId) {
            setState(() {
              _newlyAddedMealId = null;
            });
          }
        });
      }
    });
  }

  void _deleteMeal(BuildContext context, MealModel meal) async {
    final deletedMeal = meal;
    final messenger = ScaffoldMessenger.of(context);

    await meal.delete();

    if (!context.mounted) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Expanded(
              child: Text(
                '${deletedMeal.name} deleted',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final box = Hive.box<MealModel>(HiveService.mealBoxName);
                await box.put(deletedMeal.id, deletedMeal);
                messenger.hideCurrentSnackBar();
              },
              child: const Text(
                'UNDO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 187, 250, 94),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyYesterdaysMeals(String userId) async {
    final box = Hive.box<MealModel>(HiveService.mealBoxName);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final today = DateTime.now();

    final yesterdaysMeals = box.values.where((meal) {
      return meal.userId == userId && _isSameDay(meal.date, yesterday);
    }).toList();

    if (yesterdaysMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meals found from yesterday to copy.')),
      );
      return;
    }

    for (final meal in yesterdaysMeals) {
      final copiedMeal = MealModel(
        id: '${DateTime.now().microsecondsSinceEpoch}_${meal.id}',
        name: meal.name,
        calories: meal.calories,
        proteinGrams: meal.proteinGrams,
        carbsGrams: meal.carbsGrams,
        fatGrams: meal.fatGrams,
        date: today,
        userId: userId,
        mealTypeName: meal.mealTypeName,
      );
      await _dietService.addMeal(copiedMeal);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Copied ${yesterdaysMeals.length} meal(s) from yesterday!'),
        ),
      );
    }
  }

  void _openFoodSearchSheet(BuildContext context, String userId,
      {MealType? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FoodSearchSheet(
        initialMealType: initialType ?? _selectedMealType,
        userId: userId,
        onMealSelected: (meal) async {
          await _dietService.addMeal(meal);
          if (context.mounted) {
            _showMealLoggedSuccess(context, meal.id);
          }
        },
      ),
    );
  }

  void _showPortionDialogForFavorite(FoodItemModel foodItem, String userId) {
    double servingGrams = 100.0;
    final servingController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double factor = servingGrams / 100.0;
            final int cal = (foodItem.caloriesPer100g * factor).round();
            final double p = foodItem.proteinPer100g * factor;
            final double c = foodItem.carbsPer100g * factor;
            final double f = foodItem.fatPer100g * factor;

            return AlertDialog(
              title: Text(foodItem.name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (foodItem.brand != null)
                      Text(
                        foodItem.brand!,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: servingController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Serving Size (g)',
                        suffixText: 'g',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          servingGrams = double.tryParse(val) ?? 100.0;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientStat('Calories', '$cal kcal'),
                          _buildNutrientStat(
                              'Protein', '${_numberFormatter.format(p)}g'),
                          _buildNutrientStat(
                              'Carbs', '${_numberFormatter.format(c)}g'),
                          _buildNutrientStat(
                              'Fats', '${_numberFormatter.format(f)}g'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final meal = MealModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name:
                          '${foodItem.name} (${servingGrams.toStringAsFixed(0)}g)',
                      calories: cal,
                      proteinGrams: double.parse(p.toStringAsFixed(1)),
                      carbsGrams: double.parse(c.toStringAsFixed(1)),
                      fatGrams: double.parse(f.toStringAsFixed(1)),
                      date: DateTime.now(),
                      userId: userId,
                      mealTypeName: _selectedMealType.name,
                    );

                    await _dietService.addMeal(meal);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (mounted) {
                      _showMealLoggedSuccess(context, meal.id);
                    }
                  },
                  child: const Text('Log Meal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNutrientStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showAddMealModal(BuildContext outerContext,
      {MealModel? existingMeal, MealType? defaultType}) {
    final modalFormKey = GlobalKey<FormState>();
    AutovalidateMode modalAutovalidateMode = AutovalidateMode.disabled;
    bool modalShouldShake = false;

    if (existingMeal != null) {
      _nameController.text = existingMeal.name;
      final double derivedQty = _getMealQuantity(existingMeal);
      _quantityController.text = derivedQty == derivedQty.roundToDouble()
          ? derivedQty.toInt().toString()
          : derivedQty.toString();
      _caloriesController.text = existingMeal.calories.toString();
      _proteinController.text =
          _numberFormatter.format(existingMeal.proteinGrams);
      _carbsController.text = _numberFormatter.format(existingMeal.carbsGrams);
      _fatsController.text = _numberFormatter.format(existingMeal.fatGrams);
      _selectedMealType = _getMealType(existingMeal);
    } else {
      _selectedMealType = defaultType ?? MealType.breakfast;
      // Start fields empty so hint texts ("e.g. Oatmeal", "e.g. 380") appear cleanly
      _nameController.clear();
      _caloriesController.clear();
      _quantityController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatsController.clear();
    }

    void updateFromKcal(String kcalStr) {
      final kcal = double.tryParse(kcalStr.trim()) ?? 0.0;
      if (kcal <= 0) {
        _quantityController.text = '0';
        _proteinController.text = '0';
        _carbsController.text = '0';
        _fatsController.text = '0.0';
        return;
      }
      final bool isBreakfast = _selectedMealType == MealType.breakfast;
      final nameLower = _nameController.text.trim().toLowerCase();
      final bool useBreakfastFormula =
          isBreakfast || nameLower.contains('oatmeal');

      if (useBreakfastFormula) {
        final multiplier = kcal / 380.0;
        final qty = 80.0 * multiplier;
        _quantityController.text =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
        _proteinController.text = (14 * multiplier).toStringAsFixed(1);
        _carbsController.text = (60 * multiplier).toStringAsFixed(1);
        _fatsController.text = (8 * multiplier).toStringAsFixed(1);
      } else {
        final multiplier = kcal / 620.0;
        _quantityController.text = multiplier % 1 == 0
            ? multiplier.toInt().toString()
            : multiplier.toStringAsFixed(1);
        _proteinController.text = (45 * multiplier).toStringAsFixed(1);
        _carbsController.text = (70 * multiplier).toStringAsFixed(1);
        _fatsController.text = (18 * multiplier).toStringAsFixed(1);
      }
    }

    if (_caloriesController.text.isNotEmpty) {
      updateFromKcal(_caloriesController.text);
    }

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
                    : Colors.grey.shade200,
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
                  key: modalFormKey,
                  autovalidateMode: modalAutovalidateMode,
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
                          Text(
                            existingMeal == null ? 'Add Meal' : 'Edit Meal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark ? Colors.white : AppColors.textDark,
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
                      ShakeWidget(
                        shouldShake: modalShouldShake,
                        onShakeComplete: () =>
                            setModalState(() => modalShouldShake = false),
                        child: TextFormField(
                          controller: _nameController,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : AppColors.textDark),
                          decoration: fieldDecoration(
                              label: 'Meal Name',
                              hint:
                                  'e.g. Oatmeal, Chicken Rice Bowl, protein shake'),
                          onChanged: (val) {
                            setModalState(() {
                              updateFromKcal(_caloriesController.text);
                            });
                          },
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Enter meal name'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ShakeWidget(
                        shouldShake: modalShouldShake,
                        onShakeComplete: () =>
                            setModalState(() => modalShouldShake = false),
                        child: TextFormField(
                          controller: _caloriesController,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : AppColors.textDark),
                          decoration: fieldDecoration(
                              label: 'Calories (kcal)',
                              hint: 'e.g. 380',
                              suffix: 'kcal'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              updateFromKcal(val);
                            });
                          },
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Enter calories'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_caloriesController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF6F7FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Auto: ${_quantityController.text}${_selectedMealType == MealType.breakfast ? 'g' : ' bowl'} • ${_proteinController.text}P • ${_carbsController.text}C • ${_fatsController.text}F',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      _DietScaleButton(
                        onPressed: () async {
                          setModalState(() {
                            modalAutovalidateMode =
                                AutovalidateMode.onUserInteraction;
                          });
                          if (modalFormKey.currentState != null &&
                              modalFormKey.currentState!.validate()) {
                            final userId = Provider.of<AuthProvider>(
                                        outerContext,
                                        listen: false)
                                    .currentUser
                                    ?.email ??
                                'guest_user';
                            final enteredQty = double.parse((double.tryParse(
                                        _quantityController.text.trim()) ??
                                    1.0)
                                .toStringAsFixed(1));
                            final actualFat =
                                double.tryParse(_fatsController.text.trim()) ??
                                    0.0;
                            final meal = MealModel(
                              id: existingMeal?.id ??
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                              name: _nameController.text.trim(),
                              calories: int.tryParse(
                                      _caloriesController.text.trim()) ??
                                  0,
                              proteinGrams: double.tryParse(
                                      _proteinController.text.trim()) ??
                                  0.0,
                              carbsGrams: double.tryParse(
                                      _carbsController.text.trim()) ??
                                  0.0,
                              fatGrams: actualFat,
                              date: existingMeal?.date ?? DateTime.now(),
                              userId: userId,
                              mealTypeName:
                                  '${_selectedMealType.name}|$enteredQty',
                            );
                            await _dietService.addMeal(meal);
                            if (modalContext.mounted)
                              Navigator.pop(modalContext);
                            if (outerContext.mounted && existingMeal == null) {
                              _showMealLoggedSuccess(outerContext, meal.id);
                            }
                          } else {
                            HapticFeedback.heavyImpact();
                            setModalState(() => modalShouldShake = true);
                          }
                        },
                        child: Text(
                          existingMeal == null ? 'Save' : 'Update Meal',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white),
                        ),
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

  void _showAddSnackModal(BuildContext outerContext,
      {MealModel? existingMeal}) {
    final modalFormKey = GlobalKey<FormState>();
    AutovalidateMode modalAutovalidateMode = AutovalidateMode.disabled;
    bool modalShouldShake = false;

    if (existingMeal != null) {
      _snackNameController.text = existingMeal.name;
      _snackCaloriesController.text = existingMeal.calories.toString();
      _scoopController.text = (existingMeal.calories / 220).toStringAsFixed(1);
      _selectedMealType = _getMealType(existingMeal);
    } else {
      // Clear fields to reveal clean hint texts
      _snackNameController.clear();
      _snackCaloriesController.clear();
      _scoopController.clear();
      _selectedMealType = MealType.snack;
    }

    void updateSnackFromKcal(String kcalStr) {
      final kcal = double.tryParse(kcalStr.trim()) ?? 0.0;
      if (kcal <= 0) {
        _scoopController.text = '0';
        return;
      }
      final scoops = kcal / 220.0;
      _scoopController.text = scoops % 1 == 0
          ? scoops.toInt().toString()
          : scoops.toStringAsFixed(1);
    }

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
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                  key: modalFormKey,
                  autovalidateMode: modalAutovalidateMode,
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
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(existingMeal == null ? 'Add Meal' : 'Edit Meal',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textDark)),
                          GestureDetector(
                            onTap: () => Navigator.pop(modalContext),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF2F3F7),
                                  shape: BoxShape.circle),
                              child: Icon(Icons.close,
                                  size: 18,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ShakeWidget(
                        shouldShake: modalShouldShake,
                        onShakeComplete: () =>
                            setModalState(() => modalShouldShake = false),
                        child: TextFormField(
                          controller: _snackNameController,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : AppColors.textDark),
                          decoration: fieldDecoration(
                              label: 'Meal Name', hint: 'e.g. protein shake'),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Enter meal name'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ShakeWidget(
                        shouldShake: modalShouldShake,
                        onShakeComplete: () =>
                            setModalState(() => modalShouldShake = false),
                        child: TextFormField(
                          controller: _snackCaloriesController,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : AppColors.textDark),
                          decoration: fieldDecoration(
                              label: 'Calories (kcal)',
                              suffix: 'kcal',
                              hint: 'e.g. 220'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              updateSnackFromKcal(val);
                            });
                          },
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Enter calories'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                            'Auto: ${_scoopController.text.isEmpty ? "0" : _scoopController.text} scoop',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 24),
                      _DietScaleButton(
                        onPressed: () async {
                          setModalState(() {
                            modalAutovalidateMode =
                                AutovalidateMode.onUserInteraction;
                          });
                          if (modalFormKey.currentState != null &&
                              modalFormKey.currentState!.validate()) {
                            final userId = Provider.of<AuthProvider>(
                                        outerContext,
                                        listen: false)
                                    .currentUser
                                    ?.email ??
                                'guest_user';
                            final scoopVal =
                                double.tryParse(_scoopController.text.trim()) ??
                                    1.0;
                            final meal = MealModel(
                              id: existingMeal?.id ??
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                              name: _snackNameController.text.trim(),
                              calories: int.tryParse(
                                      _snackCaloriesController.text.trim()) ??
                                  220,
                              proteinGrams: scoopVal,
                              carbsGrams: 0.0,
                              fatGrams: 0.0,
                              date: existingMeal?.date ?? DateTime.now(),
                              userId: userId,
                              mealTypeName: _selectedMealType.name,
                            );
                            await _dietService.addMeal(meal);
                            if (modalContext.mounted) {
                              Navigator.pop(modalContext);
                            }
                            if (outerContext.mounted && existingMeal == null) {
                              _showMealLoggedSuccess(outerContext, meal.id);
                            }
                          } else {
                            HapticFeedback.heavyImpact();
                            setModalState(() => modalShouldShake = true);
                          }
                        },
                        child: Text(
                            existingMeal == null ? 'Save' : 'Update Meal',
                            style: const TextStyle(
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

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _initializeData();
  // }

  // Future<void> _initializeData() async {
  //   // Simulate async data/box initialization if needed
  //   await Future.delayed(const Duration(milliseconds: 500));
  //   if (mounted) {
  //     setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context).currentUser?.email ?? 'guest_user';
    final dietProvider = context.watch<DietProvider>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    const orderedMealTypes = [
      MealType.breakfast,
      MealType.lunch,
      MealType.snack,
      MealType.dinner,
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Diet',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
                fontSize: 26)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.chevron_left,
                    size: 16, color: AppColors.indigoPrimary),
                const SizedBox(width: 2),
                Text(
                  'Today',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark
                          ? const Color.fromARGB(255, 252, 252, 252)
                          : AppColors.textDark),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.indigoPrimary),
              ],
            ),
          ),
        ],
      ),
      // body: _isLoading
      //     ? AppSkeletonLoader(
      //         isDark: isDark) // Shows shimmer only during startup
      //     : ValueListenableBuilder(
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
        builder: (context, Box<MealModel> mealBox, _) {
// 1. Show your shimmer skeleton loader while the box has no data / is loading
          // if (mealBox.values.isEmpty) {
          //   return AppSkeletonLoader(isDark: isDark);
          // }

          final userMeals = mealBox.values.where((meal) {
            return meal.userId == currentUserId || meal.userId.isEmpty;
          }).toList();

          final Map<MealType, List<MealModel>> groupedMeals = {
            for (var type in MealType.values) type: [],
          };

          for (var meal in userMeals) {
            groupedMeals[_getMealType(meal)]?.add(meal);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200),
                    ),
                    child: TextField(
                      readOnly: true,
                      onTap: () => _openFoodSearchSheet(context, currentUserId),
                      decoration: InputDecoration(
                        hintText: 'Search food or scan barcode',
                        hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : AppColors.textMuted,
                            fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.grid_view_rounded,
                              color: AppColors.indigoPrimary, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BarcodeScannerScreen()),
                            );
                          },
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, top: 4.0, bottom: 4.0),
                    child: Row(
                      children: ['Recent', 'Favorites', 'Copy yesterday']
                          .map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 0),
                            labelPadding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(filter, textAlign: TextAlign.center),
                            selected: isSelected,
                            selectedColor: AppColors.indigoPrimary,
                            backgroundColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : AppColors.lightCardBg,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey.shade300
                                      : AppColors.textMuted),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            onSelected: (_) {
                              if (filter == 'Copy yesterday') {
                                _copyYesterdaysMeals(currentUserId);
                              } else {
                                if (_selectedFilter != filter) {
                                  setState(() => _selectedFilter = filter);
                                  _triggerTabAnimation();
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                if (_selectedFilter == 'Favorites')
                  ValueListenableBuilder(
                    valueListenable:
                        Hive.box<FoodItemModel>(HiveService.recentFoodsBoxName)
                            .listenable(),
                    builder: (context, Box<FoodItemModel> foodBox, _) {
                      final favorites = foodBox.values
                          .where((item) => item.isFavorite)
                          .toList();

                      if (favorites.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.star_outline,
                                    size: 48,
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No favorite foods yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Star items in Search & Add Food to see them here.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.3 : 0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: favorites.length,
                            separatorBuilder: (context, index) => Divider(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final item = favorites[index];
                              return ListTile(
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.caloriesPer100g.round()} kcal per 100g',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.star,
                                          color: Colors.amber, size: 20),
                                      onPressed: () {
                                        item.isFavorite = false;
                                        item.save();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: AppColors.indigoPrimary,
                                          size: 22),
                                      onPressed: () =>
                                          _showPortionDialogForFavorite(
                                              item, currentUserId),
                                    ),
                                  ],
                                ),
                                onTap: () => _showPortionDialogForFavorite(
                                    item, currentUserId),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  )
                else ...[
                  for (final type in orderedMealTypes) ...[
                    _buildMealGroupCard(context, type, groupedMeals[type] ?? [],
                        currentUserId, isDark),
                    const Gap(14),
                  ],
                ],
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Water',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.textDark),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: Row(
                          children: List.generate(8, (index) {
                            final isFilled = index < dietProvider.waterGlasses;
                            return GestureDetector(
                              onTap: () =>
                                  dietProvider.setWaterGlasses(index + 1),
                              child: Container(
                                width: 17,
                                height: 25,
                                margin: const EdgeInsets.only(left: 3),
                                decoration: BoxDecoration(
                                  color: isFilled
                                      ? const Color.fromARGB(255, 105, 210, 255)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.elliptical(2, 2),
                                    topRight: Radius.elliptical(2, 2),
                                    bottomLeft: Radius.elliptical(8, 8),
                                    bottomRight: Radius.elliptical(8, 8),
                                  ),
                                  border: Border.all(
                                    color: isFilled
                                        ? const Color.fromARGB(
                                            255, 105, 210, 255)
                                        : const Color.fromARGB(
                                            255, 0, 221, 255),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealGroupCard(BuildContext context, MealType type,
      List<MealModel> meals, String currentUserId, bool isDark) {
    final int groupCalories = meals.fold<int>(0, (sum, m) => sum + m.calories);

    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 14.0, right: 14.0, top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.grey : Colors.grey[700]),
                  ),
                  Row(
                    children: [
                      Text(
                        groupCalories > 0 ? '$groupCalories kcal' : '—',
                        style: TextStyle(
                            color: isDark
                                ? const Color.fromARGB(255, 253, 253, 253)
                                : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (type == MealType.snack) {
                            _showAddSnackModal(context);
                          } else {
                            _showAddMealModal(context, defaultType: type);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.indigoPrimary
                                : const Color(0xFFEEF2FF),
                          ),
                          child: Icon(Icons.add,
                              size: 18,
                              color: isDark
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark
                  ? Colors.grey.shade800
                  : const Color.fromARGB(255, 214, 214, 214),
              thickness: 1.0,
              indent: 16.0,
              endIndent: 16.0,
            ),
            if (meals.isNotEmpty) ...[
              ClipRect(
                child: ListView.builder(
                  clipBehavior: Clip.hardEdge,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  addRepaintBoundaries: true,
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    final mealType = _getMealType(meal);
                    final bool isSnackItem = mealType == MealType.snack &&
                        meal.carbsGrams == 0 &&
                        meal.fatGrams == 0;

                    final double derivedQty = _getMealQuantity(meal);
                    final double cleanDisplayQty =
                        double.parse(derivedQty.toStringAsFixed(1));
                    final String quantityDisplay = mealType ==
                            MealType.breakfast
                        ? '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} g'
                        : '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} ${cleanDisplayQty == 1 ? 'bowl' : 'bowls'}';

                    final bool isRecentlyAdded = _newlyAddedMealId == meal.id;

                    return Dismissible(
                      key: Key(meal.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      onDismissed: (_) => _deleteMeal(context, meal),
                      child: _GlowingMealRow(
                        key: ValueKey(meal.id),
                        isNew: isRecentlyAdded,
                        forceSlide: _shouldAnimateList,
                        isDark: isDark,
                        child: InkWell(
                          onTap: () {
                            if (isSnackItem) {
                              _showAddSnackModal(context, existingMeal: meal);
                            } else {
                              _showAddMealModal(context, existingMeal: meal);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: isSnackItem
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isDark
                                                    ? const Color(0xFF9CA3AF)
                                                    : AppColors.textDark),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${meal.proteinGrams == meal.proteinGrams.roundToDouble() ? meal.proteinGrams.toInt() : meal.proteinGrams} scoop${meal.proteinGrams == 1 ? '' : 's'}',
                                            style: TextStyle(
                                                color: isDark
                                                    ? const Color.fromARGB(
                                                        255, 255, 255, 255)
                                                    : const Color.fromARGB(
                                                        255, 0, 0, 0),
                                                fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFDC2626),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () =>
                                                _deleteMeal(context, meal),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              meal.name,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? const Color(0xFF9CA3AF)
                                                      : AppColors.textDark),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$quantityDisplay • ${_timeFormatter.format(meal.date)}',
                                              style: TextStyle(
                                                  color: isDark
                                                      ? const Color.fromARGB(
                                                          255, 255, 255, 255)
                                                      : const Color.fromARGB(
                                                          255, 0, 0, 0),
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _macroChip(
                                          '${meal.proteinGrams.round()}P',
                                          AppColors.proteinIndigo),
                                      const SizedBox(width: 6),
                                      _macroChip('${meal.carbsGrams.round()}C',
                                          AppColors.carbsAmber),
                                      const SizedBox(width: 6),
                                      _macroChip('${meal.fatGrams.round()}F',
                                          AppColors.fatsPink),
                                      const SizedBox(width: 5),
                                      Text(
                                        _numberFormatter.format(meal.calories),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textDark),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color.withValues(alpha: 1),
            fontSize: 7,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _GlowingMealRow extends StatefulWidget {
  final Widget child;
  final bool isNew;
  final bool isDark;
  final bool forceSlide;

  const _GlowingMealRow({
    super.key,
    required this.child,
    required this.isNew,
    required this.isDark,
    this.forceSlide = false,
  });

  @override
  State<_GlowingMealRow> createState() => _GlowingMealRowState();
}

class _GlowingMealRowState extends State<_GlowingMealRow>
    with SingleTickerProviderStateMixin {
  bool _glowActive = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    if (widget.isNew || widget.forceSlide) {
      _slideController.forward();
    } else {
      _slideController.value = 1.0;
    }

    _startGlowIfNeeded();
  }

  void _startGlowIfNeeded() {
    if (widget.isNew) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _glowActive = true);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _glowActive = false);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant _GlowingMealRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceSlide && !oldWidget.forceSlide) {
      _slideController.forward(from: 0);
    }
    if (widget.isNew && !oldWidget.isNew) {
      _glowActive = false;
      _startGlowIfNeeded();
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color normalBg = widget.isDark
        ? const Color.fromARGB(0, 42, 42, 42)
        : const Color.fromARGB(255, 253, 253, 253);

    final Color glowBg = widget.isDark
        ? const Color(0xFF324D1E)
        : const Color.fromARGB(255, 208, 252, 144);

    const Color glowBorder = Color.fromARGB(255, 153, 255, 0);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _glowActive ? glowBg : normalBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _glowActive ? glowBorder : Colors.transparent,
              width: _glowActive ? 2.5 : 0.0,
            ),
            boxShadow: _glowActive
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(255, 188, 238, 114)
                          .withValues(alpha: widget.isDark ? 0.25 : 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _DietScaleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _DietScaleButton({
    required this.onPressed,
    required this.child,
  });

  @override
  State<_DietScaleButton> createState() => _DietScaleButtonState();
}

class _DietScaleButtonState extends State<_DietScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _innerScaleAnimation;
  late Animation<double> _outerScaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );

    _innerScaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _outerScaleAnimation = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _outerScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _outerScaleAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    curve: Curves.easeOutCubic,
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
              animation: _innerScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _innerScaleAnimation.value,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeOutCubic,
                width: _isPressed ? 180 : 200,
                height: _isPressed ? 46 : 50,
                child: Material(
                  color: _isPressed
                      ? const Color(0xFF4338CA)
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

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shouldShake;
  final VoidCallback onShakeComplete;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.shouldShake,
    required this.onShakeComplete,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      HapticFeedback.heavyImpact();
      _controller.forward(from: 0.0).then((_) {
        widget.onShakeComplete();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sineValue = sin(_controller.value * pi * 4);
        final offset = sineValue * 8.0 * (1.0 - _controller.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
