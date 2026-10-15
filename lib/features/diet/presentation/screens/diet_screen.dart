import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    // Fallback calculation from fats if metadata is missing
    final type = _getMealType(meal);
    if (type == MealType.breakfast) {
      double qty = meal.fatGrams > 0 ? (meal.fatGrams / 8.0) * 80.0 : 80.0;
      return double.parse(qty.toStringAsFixed(1));
    } else if (type == MealType.lunch) {
      double qty = meal.fatGrams > 0 ? meal.fatGrams / 18.0 : 1.0;
      return double.parse(qty.toStringAsFixed(1));
    }
    return 1.0;
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
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        backgroundColor: const Color.fromARGB(255, 8, 82, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Expanded(
              child: Text('${deletedMeal.name} deleted'),
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
                  fontSize: 16,
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
        },
      ),
    );
  }

  void _showAddMealModal(BuildContext outerContext,
      {MealModel? existingMeal, MealType? defaultType}) {
    final modalFormKey = GlobalKey<FormState>();
    AutovalidateMode modalAutovalidateMode = AutovalidateMode.disabled;

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
      _nameController.text = 'Oatmeal';
      _quantityController.text = '80';
      _caloriesController.text = '380';
      _proteinController.text = '14';
      _carbsController.text = '60';
      _fatsController.text = '8';
      _selectedMealType = defaultType ?? MealType.breakfast;
    }

    void updateNutrients(String qtyStr) {
      final qty = double.tryParse(qtyStr.trim()) ?? 0.0;
      final nameLower = _nameController.text.trim().toLowerCase();

      if (nameLower.contains('oatmeal') ||
          _selectedMealType == MealType.breakfast) {
        final multiplier = qty / 80.0;
        _caloriesController.text = (380 * multiplier).round().toString();
        _proteinController.text = (14 * multiplier).toStringAsFixed(0);
        _carbsController.text = (60 * multiplier).toStringAsFixed(0);
        _fatsController.text = (8 * multiplier).toStringAsFixed(1);
      } else {
        final multiplier = qty;
        _caloriesController.text = (620 * multiplier).round().toString();
        _proteinController.text = (45 * multiplier).toStringAsFixed(0);
        _carbsController.text = (70 * multiplier).toStringAsFixed(0);
        _fatsController.text = (18 * multiplier).toStringAsFixed(1);
      }
    }

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final bool isBreakfast = _selectedMealType == MealType.breakfast;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: modalFormKey,
                  autovalidateMode: modalAutovalidateMode,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existingMeal == null ? 'Add Meal' : 'Edit Meal',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Category',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SegmentedButton<MealType>(
                        segments: MealType.values.map((type) {
                          return ButtonSegment<MealType>(
                            value: type,
                            label: Text(type.displayName,
                                style: const TextStyle(fontSize: 12)),
                            icon: Icon(type.icon, size: 16),
                          );
                        }).toList(),
                        selected: {_selectedMealType},
                        onSelectionChanged: (Set<MealType> selection) {
                          setModalState(() {
                            _selectedMealType = selection.first;
                            if (_selectedMealType == MealType.breakfast) {
                              _nameController.text = 'Oatmeal';
                              _quantityController.text = '80';
                              updateNutrients('80');
                            } else if (_selectedMealType == MealType.lunch) {
                              _nameController.text = 'Chicken Rice Bowl';
                              _quantityController.text = '1';
                              updateNutrients('1');
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Meal Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            updateNutrients(_quantityController.text);
                          });
                        },
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Enter meal name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText:
                              isBreakfast ? 'Quantity (g)' : 'Quantity (bowls)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'))
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            updateNutrients(val);
                          });
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Enter quantity';
                          if ((double.tryParse(val) ?? 0) <= 0)
                            return 'Enter valid quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Enter calories';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              decoration: const InputDecoration(
                                  labelText: 'Protein (g)',
                                  border: OutlineInputBorder()),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _carbsController,
                              decoration: const InputDecoration(
                                  labelText: 'Carbs (g)',
                                  border: OutlineInputBorder()),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _fatsController,
                              decoration: const InputDecoration(
                                  labelText: 'Fats (g)',
                                  border: OutlineInputBorder()),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigoPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
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

                            if (modalContext.mounted) {
                              Navigator.pop(modalContext);
                            }
                          }
                        },
                        child: Text(
                            existingMeal == null ? 'Save Meal' : 'Update Meal',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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

  // Specialized Snack Modal
  void _showAddSnackModal(BuildContext outerContext,
      {MealModel? existingMeal}) {
    final modalFormKey = GlobalKey<FormState>();
    AutovalidateMode modalAutovalidateMode = AutovalidateMode.disabled;

    if (existingMeal != null) {
      _snackNameController.text = existingMeal.name;
      _scoopController.text = existingMeal.proteinGrams > 0
          ? existingMeal.proteinGrams.toString()
          : '1';
      _snackCaloriesController.text = existingMeal.calories.toString();
      _selectedMealType = _getMealType(existingMeal);
    } else {
      _snackNameController.text = 'protein shake';
      _scoopController.text = '1';
      _snackCaloriesController.text = '220';
      _selectedMealType = MealType.snack;
    }

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: modalFormKey,
                  autovalidateMode: modalAutovalidateMode,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existingMeal == null ? 'Add Snack' : 'Edit Snack',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Category',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SegmentedButton<MealType>(
                        segments: MealType.values.map((type) {
                          return ButtonSegment<MealType>(
                            value: type,
                            label: Text(type.displayName,
                                style: const TextStyle(fontSize: 12)),
                            icon: Icon(type.icon, size: 16),
                          );
                        }).toList(),
                        selected: {_selectedMealType},
                        onSelectionChanged: (Set<MealType> selection) {
                          setModalState(() {
                            _selectedMealType = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _snackNameController,
                        decoration: const InputDecoration(
                          labelText: 'Meal Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Enter meal name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _scoopController,
                        decoration: const InputDecoration(
                          labelText: 'Scoop',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,1}'))
                        ],
                        onChanged: (val) {
                          final scoops = double.tryParse(val.trim()) ?? 0.0;
                          final calculatedKcal = (scoops * 220).round();
                          setModalState(() {
                            _snackCaloriesController.text =
                                calculatedKcal.toString();
                          });
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter scoop amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _snackCaloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.indigoPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
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
                          }
                        },
                        child: Text(
                            existingMeal == null
                                ? 'Save Snack'
                                : 'Update Snack',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context).currentUser?.email ?? 'guest_user';
    final today = DateTime.now();
    final dietProvider = context.watch<DietProvider>();

    // Detect current theme brightness for Dark Mode support
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
            child: const Row(
              children: [
                Icon(Icons.chevron_left,
                    size: 16, color: AppColors.indigoPrimary),
                SizedBox(width: 2),
                Text('Today',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.indigoPrimary)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right,
                    size: 16, color: AppColors.indigoPrimary),
              ],
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<MealModel>(HiveService.mealBoxName).listenable(),
        builder: (context, Box<MealModel> box, _) {
          final todayMeals = box.values.where((meal) {
            return meal.userId == currentUserId && _isSameDay(meal.date, today);
          }).toList();

          final Map<MealType, List<MealModel>> groupedMeals = {
            for (var type in MealType.values) type: [],
          };

          for (var meal in todayMeals) {
            groupedMeals[_getMealType(meal)]?.add(meal);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search bar
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

                // 2. Filter Chips
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
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // 3. Meal Groups
                for (final type in orderedMealTypes) ...[
                  _buildMealGroupCard(context, type, groupedMeals[type] ?? [],
                      currentUserId, isDark),
                  const SizedBox(height: 14),
                ],

                // 4. Water Tracker
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
                        color: isDark ? Colors.white : AppColors.textDark),
                  ),
                  Row(
                    children: [
                      Text(
                        groupCalories > 0 ? '$groupCalories kcal' : '—',
                        style: const TextStyle(
                            color: AppColors.textMuted,
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
                                ? Colors.grey.shade800
                                : const Color(0xFFEEF2FF),
                          ),
                          child: const Icon(Icons.add,
                              size: 18, color: AppColors.indigoPrimary),
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                  final String quantityDisplay = mealType == MealType.breakfast
                      ? '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} g'
                      : '${cleanDisplayQty == cleanDisplayQty.roundToDouble() ? cleanDisplayQty.toInt() : cleanDisplayQty} ${cleanDisplayQty == 1 ? 'bowl' : 'bowls'}';

                  return Dismissible(
                    key: Key(meal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                                ? Colors.white
                                                : AppColors.textDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${meal.proteinGrams == meal.proteinGrams.roundToDouble() ? meal.proteinGrams.toInt() : meal.proteinGrams} scoop${meal.proteinGrams == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 6),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                                  ? Colors.white
                                                  : AppColors.textDark),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$quantityDisplay • ${_timeFormatter.format(meal.date)}',
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _macroChip('${meal.proteinGrams.round()}P',
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
                  );
                },
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
