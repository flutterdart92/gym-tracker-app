// import 'package:flutter/material.dart';
// import 'package:gym_tracker_app/core/services/hive_service.dart';
// import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
// import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';
// import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
// import 'package:gym_tracker_app/features/workout/data/services/workout_service.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:provider/provider.dart';

// class ExerciseFormBottomSheet extends StatefulWidget {
//   final ExerciseModel? existingExercise;
//   final BuildContext outerContext;
//   final WorkoutService workoutService;

//   const ExerciseFormBottomSheet({
//     super.key,
//     required this.existingExercise,
//     required this.outerContext,
//     required this.workoutService,
//   });

//   @override
//   State<ExerciseFormBottomSheet> createState() =>
//       _ExerciseFormBottomSheetState();
// }

// class _ExerciseFormBottomSheetState extends State<ExerciseFormBottomSheet> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   late List<SetModel> _sets;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.existingExercise != null) {
//       _nameController.text = widget.existingExercise!.name;
//       _sets = (widget.existingExercise!.setsList != null &&
//               widget.existingExercise!.setsList!.isNotEmpty)
//           ? widget.existingExercise!.setsList!
//               .map((s) => SetModel(
//                   weight: s.weight,
//                   reps: s.reps,
//                   isDone: s.isDone,
//                   isPr: s.isPr))
//               .toList()
//           : List.generate(
//               widget.existingExercise!.sets,
//               (_) => SetModel(
//                   weight: widget.existingExercise!.weight,
//                   reps: widget.existingExercise!.reps),
//             );
//     } else {
//       _sets = [SetModel(weight: 60, reps: 10)];
//     }
//   }

//   void _addSet() {
//     setState(() {
//       final lastW = _sets.isNotEmpty ? _sets.last.weight : 60.0;
//       final lastR = _sets.isNotEmpty ? _sets.last.reps : 10;
//       _sets.add(SetModel(weight: lastW, reps: lastR));
//     });
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//         top: 24,
//         left: 20,
//         right: 20,
//       ),
//       child: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     widget.existingExercise == null
//                         ? 'Log Exercise'
//                         : 'Edit Exercise',
//                     style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close, color: Colors.grey),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _nameController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   labelText: 'Exercise Name (e.g., Bench Press)',
//                   labelStyle: TextStyle(color: Colors.grey),
//                   enabledBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.grey)),
//                   focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(color: Color(0xFFA3E635))),
//                   isDense: true,
//                 ),
//                 validator: (val) => val == null || val.trim().isEmpty
//                     ? 'Enter exercise name'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               ..._sets.asMap().entries.map((entry) {
//                 final idx = entry.key;
//                 final setItem = entry.value;
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 10.0),
//                   child: Row(
//                     children: [
//                       SizedBox(
//                           width: 30,
//                           child: Text('${idx + 1}',
//                               style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold))),
//                       Expanded(
//                         child: TextFormField(
//                           initialValue: setItem.weight.toString(),
//                           style: const TextStyle(color: Colors.white),
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true),
//                           decoration: const InputDecoration(
//                               labelText: 'KG',
//                               isDense: true,
//                               labelStyle: TextStyle(color: Colors.grey)),
//                           onChanged: (v) =>
//                               setItem.weight = double.tryParse(v) ?? 0.0,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextFormField(
//                           initialValue: setItem.reps.toString(),
//                           style: const TextStyle(color: Colors.white),
//                           keyboardType: TextInputType.number,
//                           decoration: const InputDecoration(
//                               labelText: 'Reps',
//                               isDense: true,
//                               labelStyle: TextStyle(color: Colors.grey)),
//                           onChanged: (v) => setItem.reps = int.tryParse(v) ?? 0,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.delete,
//                             color: Colors.redAccent, size: 20),
//                         onPressed: () {
//                           if (_sets.length > 1) {
//                             setState(() => _sets.removeAt(idx));
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//               OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                     foregroundColor: const Color(0xFFA3E635)),
//                 onPressed: _addSet,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Set'),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFA3E635),
//                   foregroundColor: Colors.black,
//                   minimumSize: const Size.fromHeight(50),
//                 ),
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     final authProvider = Provider.of<AuthProvider>(
//                         widget.outerContext,
//                         listen: false);
//                     final topWeight = _sets.fold<double>(
//                         0.0, (max, s) => s.weight > max ? s.weight : max);
//                     final topReps = _sets.isNotEmpty ? _sets.first.reps : 0;

//                     final exercise = ExerciseModel(
//                       id: widget.existingExercise?.id ??
//                           DateTime.now().millisecondsSinceEpoch.toString(),
//                       name: _nameController.text.trim(),
//                       sets: _sets.length,
//                       reps: topReps,
//                       weight: topWeight,
//                       createdAt:
//                           widget.existingExercise?.createdAt ?? DateTime.now(),
//                       userId: widget.existingExercise?.userId ??
//                           (authProvider.currentUser?.email ?? ''),
//                       setsList: _sets,
//                     );

//                     final box =
//                         Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
//                     await box.put(exercise.id, exercise);

//                     if (mounted) Navigator.pop(context);
//                   }
//                 },
//                 child: Text(
//                     widget.existingExercise == null
//                         ? 'Save Exercise'
//                         : 'Update Exercise',
//                     style: const TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
import 'package:gym_tracker_app/features/workout/data/services/workout_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class ExerciseFormBottomSheet extends StatefulWidget {
  final ExerciseModel? existingExercise;
  final BuildContext outerContext;
  final WorkoutService workoutService;

  const ExerciseFormBottomSheet({
    super.key,
    required this.existingExercise,
    required this.outerContext,
    required this.workoutService,
  });

  @override
  State<ExerciseFormBottomSheet> createState() =>
      _ExerciseFormBottomSheetState();
}

class _ExerciseFormBottomSheetState extends State<ExerciseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  final TextEditingController _nameController = TextEditingController();
  late List<SetModel> _sets;

  @override
  void initState() {
    super.initState();
    if (widget.existingExercise != null) {
      _nameController.text = widget.existingExercise!.name;
      _sets = (widget.existingExercise!.setsList != null &&
              widget.existingExercise!.setsList!.isNotEmpty)
          ? widget.existingExercise!.setsList!
              .map((s) => SetModel(
                  weight: s.weight,
                  reps: s.reps,
                  isDone: s.isDone,
                  isPr: s.isPr))
              .toList()
          : List.generate(
              widget.existingExercise!.sets,
              (_) => SetModel(
                  weight: widget.existingExercise!.weight,
                  reps: widget.existingExercise!.reps),
            );
    } else {
      _sets = [SetModel(weight: 60, reps: 10)];
    }
  }

  void _addSet() {
    setState(() {
      final lastW = _sets.isNotEmpty ? _sets.last.weight : 60.0;
      final lastR = _sets.isNotEmpty ? _sets.last.reps : 10;
      _sets.add(SetModel(weight: lastW, reps: lastR));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const lime = Color(0xFFA3E635);

    InputDecoration fieldDecoration(
        {required String label, String? hint, String? suffix}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        hintStyle: TextStyle(
          fontSize: 11,
          // color: Colors.grey.shade400
          color: isDark
              ? const Color.fromARGB(255, 255, 255, 255)
              : Colors.grey.shade200,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold,
          // color: lime
          color: isDark ? lime : lime,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF6F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar - same as diet
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
              // Header - same layout as diet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingExercise == null
                        ? 'Log Exercise'
                        : 'Edit Exercise',
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
              // Exercise Name - same field style as Meal Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                decoration: fieldDecoration(
                    label: 'Exercise Name', hint: 'e.g., Bench Press'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter exercise name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Sets - now with same rounded field style
              ..._sets.asMap().entries.map((entry) {
                final idx = entry.key;
                final setItem = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: setItem.weight.toString(),
                          style: TextStyle(
                              // color: Colors.white,
                              color: isDark
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(255, 19, 19, 19),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: fieldDecoration(label: 'KG', hint: '60'),
                          onChanged: (v) =>
                              setItem.weight = double.tryParse(v) ?? 0.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: setItem.reps.toString(),
                          style: TextStyle(
                              // color: Colors.white,
                              color: isDark
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(255, 19, 19, 19),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          keyboardType: TextInputType.number,
                          decoration:
                              fieldDecoration(label: 'Reps', hint: '10'),
                          onChanged: (v) => setItem.reps = int.tryParse(v) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_sets.length > 1) {
                            setState(() => _sets.removeAt(idx));
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF2F3F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Add Set button - outlined style but with same rounded feel as diet's secondary
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    // foregroundColor: lime,
                    foregroundColor:
                        isDark ? lime : const Color.fromARGB(255, 0, 0, 0),

                    side: const BorderSide(color: lime, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF6F7FB),
                  ),
                  onPressed: _addSet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Set',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),

              const SizedBox(height: 24),

              // Save button - SAME layout as diet's _HapticScaleButton but LIME color
              _WorkoutHapticButton(
                onPressed: () async {
                  setState(
                      () => _autoValidate = AutovalidateMode.onUserInteraction);
                  if (_formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(
                        widget.outerContext,
                        listen: false);
                    final topWeight = _sets.fold<double>(
                        0.0, (max, s) => s.weight > max ? s.weight : max);
                    final topReps = _sets.isNotEmpty ? _sets.first.reps : 0;

                    final exercise = ExerciseModel(
                      id: widget.existingExercise?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      sets: _sets.length,
                      reps: topReps,
                      weight: topWeight,
                      createdAt:
                          widget.existingExercise?.createdAt ?? DateTime.now(),
                      userId: widget.existingExercise?.userId ??
                          (authProvider.currentUser?.email ?? ''),
                      setsList: _sets,
                    );

                    final box =
                        Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
                    await box.put(exercise.id, exercise);

                    if (mounted) Navigator.pop(context);
                  } else {
                    HapticFeedback.heavyImpact();
                  }
                },
                child: Text(
                  widget.existingExercise == null
                      ? 'Save Exercise'
                      : 'Update Exercise',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same animation as diet's _HapticScaleButton but with workout lime colors
class _WorkoutHapticButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const _WorkoutHapticButton({required this.onPressed, required this.child});

  @override
  State<_WorkoutHapticButton> createState() => _WorkoutHapticButtonState();
}

class _WorkoutHapticButtonState extends State<_WorkoutHapticButton>
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
    const lime = Color(0xFFA3E635);
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
                          // ? const Color(0xFF2A2A2A)
                          // : const Color(0xFF1E1E1E),
                          ? const Color.fromARGB(255, 213, 255, 150)
                          : const Color.fromARGB(255, 213, 255, 150),
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
                // height: _isPressed ? 60 : 50,

                child: Material(
                  color: _isPressed ? const Color(0xFF84CC16) : lime,
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
