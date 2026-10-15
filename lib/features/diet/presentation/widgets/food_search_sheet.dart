import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/hive_service.dart';
import '../../data/models/food_item_model.dart';
import '../../data/models/meal_model.dart';
import '../../data/models/meal_type.dart';
import '../../data/services/open_food_facts_service.dart';
import '../screens/barcode_scanner_screen.dart';

class FoodSearchSheet extends StatefulWidget {
  final MealType initialMealType;
  final String userId;
  final Function(MealModel) onMealSelected;

  const FoodSearchSheet({
    super.key,
    required this.initialMealType,
    required this.userId,
    required this.onMealSelected,
  });

  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MealType _selectedMealType;
  final OpenFoodFactsService _offService = OpenFoodFactsService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  Timer? _debounceTimer;
  List<FoodItemModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      setState(() => _isLoading = true);
      final results = await _offService.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      final foodItem = await _offService.fetchByBarcode(barcode);
      setState(() => _isLoading = false);

      if (foodItem != null && mounted) {
        _showPortionDialog(foodItem);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No food found for barcode: $barcode')),
        );
      }
    }
  }

  void _showPortionDialog(FoodItemModel foodItem) {
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
                              'Protein', '${_formatter.format(p)}g'),
                          _buildNutrientStat(
                              'Carbs', '${_formatter.format(c)}g'),
                          _buildNutrientStat(
                              'Fats', '${_formatter.format(f)}g'),
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
                    final box =
                        Hive.box<FoodItemModel>(HiveService.recentFoodsBoxName);
                    await box.put(foodItem.id, foodItem);

                    final meal = MealModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name:
                          '${foodItem.name} (${servingGrams.toStringAsFixed(0)}g)',
                      calories: cal,
                      proteinGrams: double.parse(p.toStringAsFixed(1)),
                      carbsGrams: double.parse(c.toStringAsFixed(1)),
                      fatGrams: double.parse(f.toStringAsFixed(1)),
                      date: DateTime.now(),
                      userId: widget.userId,
                      mealTypeName: _selectedMealType.name,
                    );

                    widget.onMealSelected(meal);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search & Add Food',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 15,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, // <-- WIDTH of whole button
            height: 50,
            child: SegmentedButton<MealType>(
              selectedIcon: const Icon(Icons.check, size: 12),
              segments: MealType.values.map((type) {
                return ButtonSegment<MealType>(
                  value: type,
                  label: Text(type.displayName,
                      style: const TextStyle(fontSize: 8)),
                  icon: Icon(type.icon, size: 10),
                );
              }).toList(),
              selected: {_selectedMealType},
              onSelectionChanged: (Set<MealType> selection) {
                setState(() {
                  _selectedMealType = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),

            unselectedLabelStyle:
                const TextStyle(fontSize: 10), // unselected size

            tabs: const [
              Tab(
                  // height: 12,
                  text: 'Food Database',
                  icon: Icon(
                    Icons.search,
                    size: 18,
                  )),
              Tab(
                  text: 'Recents & Favorites',
                  icon: Icon(
                    Icons.star_outline,
                    size: 18,
                  )),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            // textAlign: TextAlign.center,
                            cursorHeight: 20,
                            // cursorRadius: rad,
                            // decoration: InputDecoration(
                            //   hint: const Row(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       Icon(Icons.search, size: 15),
                            //       SizedBox(width: 6),
                            //       Text('Search food (e.g. Oatmeal, Eggs)',
                            //           style: TextStyle(fontSize: 10)),
                            //     ],
                            //   ),
                            //   border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(12)),
                            //   contentPadding:
                            //       const EdgeInsets.symmetric(vertical: 14),
                            //   isDense: true,
                            // ),
                            decoration: InputDecoration(
                              hint: const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text(
                                  'Search food (e.g. Oatmeal, Eggs)',

                                  style: TextStyle(
                                    fontSize: 9,
                                  ),
                                  // textAlign: TextAlign.center,
                                ),
                              ),
                              // hintStyle: const TextStyle(fontSize: 5),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 15,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 5),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan Barcode',
                          onPressed: _scanBarcode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                    else if (_searchResults.isEmpty &&
                        _searchController.text.isNotEmpty)
                      const Expanded(
                          child:
                              Center(child: Text('No matching foods found.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.brand != null ? "${item.brand} • " : ""}${item.caloriesPer100g.round()} kcal per 100g',
                              ),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () => _showPortionDialog(item),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable:
                      Hive.box<FoodItemModel>(HiveService.recentFoodsBoxName)
                          .listenable(),
                  builder: (context, Box<FoodItemModel> box, _) {
                    final items = box.values.toList();
                    items.sort((a, b) {
                      if (a.isFavorite != b.isFavorite) {
                        return a.isFavorite ? -1 : 1;
                      }
                      return b.lastUsed.compareTo(a.lastUsed);
                    });

                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No recently logged or favorite foods.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.caloriesPer100g.round()} kcal per 100g',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  item.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: item.isFavorite ? Colors.amber : null,
                                ),
                                onPressed: () {
                                  item.isFavorite = !item.isFavorite;
                                  item.save();
                                },
                              ),
                              const Icon(Icons.add_circle_outline),
                            ],
                          ),
                          onTap: () => _showPortionDialog(item),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
