import 'dart:math';

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

  // bool _shouldShakeForm = false;
  //udpated :
  bool _shakeName = false;
  // newly added
  List<bool> _shakeWeights = [];
  List<bool> _shakeReps = [];
  String? _duplicateErrorMessage;
  // newly added :
  int? _newlyAddedSetIndex;

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
                  reps: widget.existingExercise!.reps));
    } else {
      _sets = [SetModel(weight: 0, reps: 0)];
    }
    // newly added
    _shakeWeights = List.generate(_sets.length, (_) => false);
    _shakeReps = List.generate(_sets.length, (_) => false);
  }

  // void _addSet() {
  //   setState(() {
  //     final lastW = _sets.isNotEmpty ? _sets.last.weight : 0.0;
  //     final lastR = _sets.isNotEmpty ? _sets.last.reps : 0;
  //     _sets.add(SetModel(weight: lastW, reps: lastR));
  //     // newly added
  //     _shakeWeights.add(false);
  //     _shakeReps.add(false);
  //   });
  // }

/*


updated _addSet() : : 


*/

  void _addSet() {
    final lastW = _sets.isNotEmpty ? _sets.last.weight : 0.0;
    final lastR = _sets.isNotEmpty ? _sets.last.reps : 0;

    // Check for duplicate set (same weight and reps)
    final bool duplicateExists = _sets.any(
      (s) => s.weight == lastW && s.reps == lastR,
    );

    if (duplicateExists) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF161B22),
          content: Text(
            'This set already exists!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _sets.add(SetModel(weight: lastW, reps: lastR));
      _shakeWeights.add(false);
      _shakeReps.add(false);
      _newlyAddedSetIndex = _sets.length - 1;
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && _newlyAddedSetIndex == _sets.length - 1) {
        setState(() => _newlyAddedSetIndex = null);
      }
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

    InputDecoration fieldDecoration({
      required String label,
      String? hint,
      String? suffix,
      bool hasError = false,
    }) {
      final labelColor = hasError
          ? Colors.redAccent
          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
      final activeColor = hasError ? Colors.redAccent : lime;

      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          // color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
          color: labelColor,
        ),
        hintStyle: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
        floatingLabelStyle: TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold,
          // color: lime
          color: activeColor,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF6F7FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          // borderSide: BorderSide(
          //     color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)
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
          // borderSide: BorderSide(
          //     color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          // borderSide: const BorderSide(color: lime, width: 1.2)
          borderSide: BorderSide(color: activeColor, width: 1.2),
        ),
        // newly added :
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131313) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 12,
          left: 20,
          right: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate,
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
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827))),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                                    isDark ? Colors.white70 : Colors.black87)),
                      ),
                    ]),
                const SizedBox(height: 20),
                ShakeWidget(
                  // shouldShake: _shouldShakeForm,
                  // udpated :
                  shouldShake: _shakeName,
                  onShakeComplete: () => setState(() => _shakeName = false),
                  child: TextFormField(
                      controller: _nameController,
                      // newly added
                      // onChanged: (_) {
                      //   if (_duplicateErrorMessage != null) {
                      //     setState(() => _duplicateErrorMessage = null);
                      //   }
                      // },
                      // updated :
                      onChanged: (_) {
                        setState(() {
                          if (_duplicateErrorMessage != null) {
                            _duplicateErrorMessage = null;
                          }
                        });
                      },
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      decoration: fieldDecoration(
                        label: 'Exercise Name',
                        hint: 'e.g., Bench Press',
                        // newly added
                        // hasError: _duplicateErrorMessage != null,
                        // updated :
                        hasError: (_nameController.text.trim().isEmpty ||
                                _duplicateErrorMessage != null) &&
                            (_autoValidate != AutovalidateMode.disabled),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter exercise name';
                        }
                        if (_duplicateErrorMessage != null) {
                          return _duplicateErrorMessage;
                        }
                        return null;
                      }),
                ),
                const SizedBox(height: 16),
                ..._sets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final setItem = entry.value;
                  // newly added :
                  final bool isNewSet = _newlyAddedSetIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _GlowingSetRow(
                      // newly updated glowing row :
                      key: Key('set_row_$idx'),
                      isNew: isNewSet,
                      isDark: isDark,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 24,
                                child: Text('${idx + 1}',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ShakeWidget(
                                // shouldShake: _shouldShakeForm,
                                //updated :
                                shouldShake: idx < _shakeWeights.length
                                    ? _shakeWeights[idx]
                                    : false,
                                // onShakeComplete: () =>
                                // setState(() => _shouldShakeForm = false),
                                //updated :
                                onShakeComplete: () => setState(() {
                                  if (idx < _shakeWeights.length) {
                                    _shakeWeights[idx] = false;
                                  }
                                }),
                                child: TextFormField(
                                    initialValue: setItem.weight > 0
                                        ? setItem.weight.toString()
                                        : '',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF131313),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: fieldDecoration(
                                      label: 'KG',
                                      hint: '60',
                                      // newly added :
                                      hasError: setItem.weight <= 0 &&
                                          (_autoValidate !=
                                              AutovalidateMode.disabled),
                                    ),
                                    validator: (val) =>
                                        val == null || val.trim().isEmpty
                                            ? 'Enter KG'
                                            : null,
                                    // onChanged: (v) => setItem.weight =
                                    //     double.tryParse(v) ?? 0.0
                                    // updated :
                                    onChanged: (v) => setState(() {
                                          setItem.weight =
                                              double.tryParse(v) ?? 0.0;
                                        })),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ShakeWidget(
                                  // shouldShake: _shouldShakeForm,
                                  // onShakeComplete: () =>
                                  //     setState(() => _shouldShakeForm = false),
                                  //updated :
                                  shouldShake: idx < _shakeReps.length
                                      ? _shakeReps[idx]
                                      : false,
                                  onShakeComplete: () => setState(() {
                                        if (idx < _shakeReps.length) {
                                          _shakeReps[idx] = false;
                                        }
                                      }),
                                  child: TextFormField(
                                      initialValue: setItem.reps > 0
                                          ? setItem.reps.toString()
                                          : '',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF131313),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                      keyboardType: TextInputType.number,
                                      decoration: fieldDecoration(
                                        label: 'Reps',
                                        hint: '10',
                                        hasError: setItem.reps <= 0 &&
                                            (_autoValidate !=
                                                AutovalidateMode.disabled),
                                      ),
                                      validator: (val) =>
                                          val == null || val.trim().isEmpty
                                              ? 'Enter Reps'
                                              : null,
                                      // onChanged: (v) =>
                                      //     setItem.reps = int.tryParse(v) ?? 0
                                      // updated :
                                      onChanged: (v) => setState(() {
                                            setItem.reps = int.tryParse(v) ?? 0;
                                          }))),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (_sets.length > 1) {
                                  // setState(() => _sets.removeAt(idx));
                                  // updated :
                                  setState(() {
                                    _sets.removeAt(idx);
                                    if (idx < _shakeWeights.length) {
                                      _shakeWeights.removeAt(idx);
                                    }
                                    if (idx < _shakeReps.length) {
                                      _shakeReps.removeAt(idx);
                                    }
                                  });
                                }
                              },
                              child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFF2F3F7),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 18)),
                            ),
                          ]),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? lime : Colors.black,
                        side: const BorderSide(color: lime, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        backgroundColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF6F7FB)),
                    onPressed: _addSet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Set',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),
                _WorkoutHapticButton(
                  onPressed: () async {
                    _duplicateErrorMessage = null;
                    final authProvider = Provider.of<AuthProvider>(
                        widget.outerContext,
                        listen: false);
                    final currentUserId =
                        (authProvider.currentUser?.email ?? '').toLowerCase();
                    final enteredName =
                        _nameController.text.trim().toLowerCase();

                    final box =
                        Hive.box<ExerciseModel>(HiveService.exerciseBoxName);

                    final existingDup = box.values.any((e) =>
                        (e.userId.toLowerCase() == currentUserId ||
                            e.userId.isEmpty) &&
                        e.name.trim().toLowerCase() == enteredName &&
                        e.id != widget.existingExercise?.id);

                    if (existingDup) {
                      setState(() {
                        _duplicateErrorMessage =
                            'Exercise "$enteredName" already exists';
                        _autoValidate = AutovalidateMode.always;
                        // _shouldShakeForm = true;
                        // changed :
                        _shakeName = true;
                      });
                      HapticFeedback.heavyImpact();
                      return;
                    }
// newly added
                    // Check for duplicate set combinations before saving
                    final Set<String> seenSets = {};
                    bool duplicateSetFound = false;
                    for (var s in _sets) {
                      final key = '${s.weight}_${s.reps}';
                      if (seenSets.contains(key)) {
                        duplicateSetFound = true;
                        break;
                      }
                      seenSets.add(key);
                    }

                    if (duplicateSetFound) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF161B22),
                          content: Text(
                            'This set already exists!',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    setState(() =>
                        _autoValidate = AutovalidateMode.onUserInteraction);

                    // newly added ;

                    final bool nameHasError =
                        _nameController.text.trim().isEmpty;
                    List<bool> weightErrors = [];
                    List<bool> repsErrors = [];
                    bool setsHaveError = false;

                    for (var s in _sets) {
                      final wErr = s.weight <= 0;
                      final rErr = s.reps <= 0;
                      weightErrors.add(wErr);
                      repsErrors.add(rErr);
                      if (wErr || rErr) setsHaveError = true;
                    }

                    if (nameHasError || setsHaveError) {
                      setState(() {
                        _shakeName = nameHasError;
                        _shakeWeights = weightErrors;
                        _shakeReps = repsErrors;
                      });
                      HapticFeedback.heavyImpact();
                      return;
                    }

                    if (_formKey.currentState!.validate()) {
                      final topWeight = _sets.fold<double>(
                          0.0, (max, s) => s.weight > max ? s.weight : max);
                      final topReps = _sets.isNotEmpty ? _sets.first.reps : 0;

                      final exercise = ExerciseModel(
                        id: widget.existingExercise?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text.trim(),
                        sets: _sets.length,
                        reps: topReps == 0 ? 10 : topReps,
                        weight: topWeight == 0 ? 60.0 : topWeight,
                        createdAt: widget.existingExercise?.createdAt ??
                            DateTime.now(),
                        userId: currentUserId,
                        setsList: _sets,
                      );

                      await box.put(exercise.id, exercise);

                      if (mounted) Navigator.pop(context, true);
                    } else {
                      HapticFeedback.heavyImpact();
                      // removed
                      // setState(() => _shouldShakeForm = true);
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
              ]),
        ),
      ),
    );
  }
}

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
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
              animation: _outerScale,
              builder: (context, child) => Transform.scale(
                  scale: _outerScale.value,
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 60),
                      width: _isPressed ? 180 : 200,
                      height: _isPressed ? 60 : 50,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 213, 255, 150),
                          borderRadius:
                              BorderRadius.circular(_isPressed ? 30 : 28))))),
          AnimatedBuilder(
              animation: _innerScale,
              builder: (context, child) =>
                  Transform.scale(scale: _innerScale.value, child: child),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: _isPressed ? 180 : 200,
                  height: _isPressed ? 46 : 50,
                  child: Material(
                      color: _isPressed ? const Color(0xFF84CC16) : lime,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: Center(child: widget.child)))),
        ]),
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

// glow row added :

// 100% Identical Slide & Glow Animation Widget matching Diet page (_GlowingMealRow)
class _GlowingSetRow extends StatefulWidget {
  final Widget child;
  final bool isNew;
  final bool isDark;
  final bool forceSlide;

  const _GlowingSetRow({
    super.key,
    required this.child,
    required this.isNew,
    required this.isDark,
    this.forceSlide = false,
  });

  @override
  State<_GlowingSetRow> createState() => _GlowingSetRowState();
}

class _GlowingSetRowState extends State<_GlowingSetRow>
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
  void didUpdateWidget(covariant _GlowingSetRow oldWidget) {
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
            borderRadius: BorderRadius.circular(14),
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
