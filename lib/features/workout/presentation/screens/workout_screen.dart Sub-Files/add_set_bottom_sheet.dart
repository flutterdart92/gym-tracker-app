import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import '../../../../auth/data/models/set_model.dart';
import '../../../data/models/exercise_model.dart';

class AddSetBottomSheet extends StatefulWidget {
  final ExerciseModel exercise;

  const AddSetBottomSheet({
    super.key,
    required this.exercise,
  });

  @override
  State<AddSetBottomSheet> createState() => _AddSetBottomSheetState();
}

class _AddSetBottomSheetState extends State<AddSetBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  bool _shakeWeight = false;
  bool _shakeReps = false;
  // added
  bool _showDuplicateError = false; // Tracks duplicate warning banner

  @override
  // void initState() {
  //   super.initState();
  //   final sets = widget.exercise.setsList ?? [];
  //   final lastWeight = sets.isNotEmpty ? sets.last.weight : 0.0;
  //   final lastReps = sets.isNotEmpty ? sets.last.reps : 0;

  //   _weightController = TextEditingController(
  //       text: lastWeight > 0
  //           ? lastWeight.toString().replaceAll(RegExp(r'\.0$'), '')
  //           : '');
  //   _repsController =
  //       TextEditingController(text: lastReps > 0 ? lastReps.toString() : '');
  // }

  //update
  @override
  void initState() {
    super.initState();
    // Leave text empty so only hints appear
    _weightController = TextEditingController(text: '');
    _repsController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _saveSet() async {
    final double weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final int reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (weight <= 0 || reps <= 0) {
      setState(() {
        _shakeWeight = weight <= 0;
        _shakeReps = reps <= 0;
        // added

        _showDuplicateError = false;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    final List<SetModel> sets = List.from(widget.exercise.setsList ?? []);

    // Check if duplicate set exists in the exercise log
    final bool duplicateExists =
        sets.any((s) => s.weight == weight && s.reps == reps);

    // if (duplicateExists) {
    //   HapticFeedback.heavyImpact();
    //   ScaffoldMessenger.of(context).clearSnackBars();
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       behavior: SnackBarBehavior.floating,
    //       backgroundColor: Color(0xFF161B22),
    //       content: Text(
    //         'This set already exists!',
    //         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    //       ),
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    //   return;
    // }

    if (duplicateExists) {
      HapticFeedback.heavyImpact();
      setState(() {
        _showDuplicateError = true;
      });
      return;
    }
    // udated position from bottom to top
    // if (duplicateExists) {
    //   HapticFeedback.heavyImpact();
    //   ScaffoldMessenger.of(context).clearSnackBars();

    //   final double screenHeight = MediaQuery.of(context).size.height;

    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       behavior: SnackBarBehavior.floating,
    //       backgroundColor: const Color(0xFF161B22),
    //       // Position it near the top of the screen
    //       margin: EdgeInsets.only(
    //         bottom: screenHeight - 160,
    //         left: 20,
    //         right: 20,
    //       ),
    //       content: const Text(
    //         'This set already exists!',
    //         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    //       ),
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    //   return;
    // }

    // Add new set to list
    sets.add(SetModel(weight: weight, reps: reps));

    // Save updated ExerciseModel to Hive box
    final box = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
    final updatedExercise = ExerciseModel(
      id: widget.exercise.id,
      name: widget.exercise.name,
      sets: sets.length,
      reps: reps,
      weight: weight,
      createdAt: widget.exercise.createdAt,
      userId: widget.exercise.userId,
      setsList: sets,
    );

    await box.put(updatedExercise.id, updatedExercise);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const lime = Color(0xFFA3E635);

    InputDecoration fieldDecoration({
      required String label,
      required String hint,
      bool hasError = false,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: hasError
              ? Colors.redAccent
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF6F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError
                ? Colors.redAccent
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError
                ? Colors.redAccent
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lime, width: 1.2),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131313) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Set',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

// added

            // Top Error Banner inside the bottom sheet if duplicate exists
            if (_showDuplicateError)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This set already exists!',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showDuplicateError = false),
                      child: const Icon(Icons.close,
                          color: Colors.redAccent, size: 16),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 200)),

            Row(
              children: [
                Expanded(
                  child: ShakeWidget(
                    shouldShake: _shakeWeight,
                    onShakeComplete: () => setState(() => _shakeWeight = false),
                    child: TextFormField(
                      controller: _weightController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF131313),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: fieldDecoration(
                        label: 'Weight (KG)',
                        hint: '60',
                        hasError: _shakeWeight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShakeWidget(
                    shouldShake: _shakeReps,
                    onShakeComplete: () => setState(() => _shakeReps = false),
                    child: TextFormField(
                      controller: _repsController,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF131313),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: fieldDecoration(
                        label: 'Reps',
                        hint: '10',
                        hasError: _shakeReps,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lime,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveSet,
                child: const Text(
                  'Add Set',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
