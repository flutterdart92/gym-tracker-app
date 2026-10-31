// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
// import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
// import 'package:hive/hive.dart';

// class SetRowItem extends StatelessWidget {
//   final int index;
//   final SetModel setItem;
//   final ExerciseModel exercise;
//   final String prevStr;
//   final bool isDark;
//   final Box<ExerciseModel> box;
//   final int exerciseIndex;
//   final List<ExerciseModel> exercises;
//   final VoidCallback onTapPr;
//   final VoidCallback onToggleDone;
//   final Function(double) onWeightChanged;
//   final Function(int) onRepsChanged;

//   const SetRowItem({
//     super.key,
//     required this.index,
//     required this.setItem,
//     required this.exercise,
//     required this.prevStr,
//     required this.isDark,
//     required this.box,
//     required this.exerciseIndex,
//     required this.exercises,
//     required this.onTapPr,
//     required this.onToggleDone,
//     required this.onWeightChanged,
//     required this.onRepsChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTapPr,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 6),
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//         decoration: BoxDecoration(
//           gradient: setItem.isPr
//               ? const LinearGradient(
//                   colors: [Color(0xFFFACC15), Color(0xFFCA8A04)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//               : null,
//           color: setItem.isPr
//               ? null
//               : (setItem.isDone
//                   ? const Color(0xFFA3E635).withValues(alpha: 0.12)
//                   : (isDark ? const Color(0xFF21262D) : Colors.grey[200])),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           children: [
//             if (setItem.isPr) ...[
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     'Est. 1RM ${(setItem.weight * (1 + (setItem.reps / 30.0))).round()} kg',
//                     style: const TextStyle(
//                       color: Colors.black87,
//                       fontSize: 17,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ).animate(onPlay: (c) => c.repeat()).shimmer(
//                       duration: const Duration(milliseconds: 1200),
//                       color: Colors.white,
//                     ),
//               ),
//               // .animate(onPlay: (c) => c.repeat()).shimmer(
//               //       duration: const Duration(milliseconds: 1200),
//               //       color: Colors.white,
//               //     ),
//             ]

//             // if (setItem.isPr) ...[
//             //   Expanded(
//             //     child: Stack(
//             //       alignment: Alignment.center,
//             //       children: [
//             //         // 1. Background with shimmer BEHIND
//             //         Container(
//             //           height: double.infinity,
//             //           decoration: BoxDecoration(
//             //             gradient: const LinearGradient(
//             //               colors: [Color(0xFFFACC15), Color(0xFFCA8A04)],
//             //               begin: Alignment.topLeft,
//             //               end: Alignment.bottomRight,
//             //             ),
//             //             borderRadius: BorderRadius.circular(10),
//             //           ),
//             //         ).animate(onPlay: (c) => c.repeat()).shimmer(
//             //               duration: const Duration(milliseconds: 1200),
//             //               color: Colors.white.withValues(alpha: 0.8),
//             //             ),
//             //         // 2. Text ON TOP - no shimmer
//             //         Text(
//             //           'Est. 1RM ${(setItem.weight * (1 + (setItem.reps / 30.0))).round()} kg',
//             //           style: const TextStyle(
//             //             color: Colors.black87,
//             //             fontSize: 17,
//             //             fontWeight: FontWeight.bold,
//             //           ),
//             //         ),
//             //       ],
//             //     ),
//             //   ),
//             // ]
//             else ...[
//               SizedBox(
//                 width: 35,
//                 child: Center(
//                   child: Text(
//                     index == 0 ? 'W' : '$index',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: index == 0
//                           ? Colors.amber
//                           : (isDark ? Colors.white : Colors.black87),
//                     ),
//                   ),
//                 ),
//               ),
//               // .animate(onPlay: (c) => c.repeat()).shimmer(
//               //       duration: const Duration(milliseconds: 1200),
//               //       color: Colors.white,
//               //     ),
//               Expanded(
//                 flex: 3,
//                 child: Text(prevStr,
//                     style: TextStyle(
//                         color: isDark ? Colors.grey : Colors.grey[700],
//                         fontSize: 13)),
//               ),
//               // .animate(onPlay: (c) => c.repeat()).shimmer(
//               //       duration: const Duration(milliseconds: 1200),
//               //       color: Colors.white,
//               //     ),
//               Expanded(
//                 flex: 2,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6),
//                   decoration: BoxDecoration(
//                     color: setItem.isDone
//                         ? Colors.transparent
//                         : (isDark ? const Color(0xFF30363D) : Colors.white),
//                     borderRadius: BorderRadius.circular(6),
//                     border:
//                         Border.all(color: Colors.grey.withValues(alpha: 0.3)),
//                   ),
//                   child: TextFormField(
//                     initialValue: setItem.weight
//                         .toString()
//                         .replaceAll(RegExp(r'\.0$'), ''),
//                     style: TextStyle(
//                         color: isDark ? Colors.white : Colors.black87,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14),
//                     keyboardType:
//                         const TextInputType.numberWithOptions(decimal: true),
//                     decoration: const InputDecoration(
//                         border: InputBorder.none, isDense: true),
//                     onChanged: (v) =>
//                         onWeightChanged(double.tryParse(v) ?? 0.0),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 flex: 2,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 6),
//                   decoration: BoxDecoration(
//                     color: setItem.isDone
//                         ? Colors.transparent
//                         : (isDark ? const Color(0xFF30363D) : Colors.white),
//                     borderRadius: BorderRadius.circular(6),
//                     border:
//                         Border.all(color: Colors.grey.withValues(alpha: 0.3)),
//                   ),
//                   child: TextFormField(
//                     initialValue: setItem.reps.toString(),
//                     style: TextStyle(
//                         color: isDark ? Colors.white : Colors.black87,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14),
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(
//                         border: InputBorder.none, isDense: true),
//                     onChanged: (v) => onRepsChanged(int.tryParse(v) ?? 0),
//                   ),
//                 ),
//               ),
//               // .animate(onPlay: (c) => c.repeat()).shimmer(
//               //       duration: const Duration(milliseconds: 1200),
//               //       color: Colors.white,
//               //     ),
//               const SizedBox(width: 4),
//               GestureDetector(
//                 onTap: onToggleDone,
//                 child: Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: setItem.isDone
//                         ? const Color(0xFFA3E635)
//                         : (isDark ? const Color(0xFF30363D) : Colors.grey[300]),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   // .animate(onPlay: (c) => c.repeat()).shimmer(
//                   //   duration: const Duration(milliseconds: 1200),
//                   //   color: Colors.white,
//                   // ),
//                   child: Icon(
//                     Icons.check,
//                     size: 20,
//                     color: setItem.isDone ? Colors.black : Colors.grey,
//                   ),
//                 ),
//               ),
//               // .animate(onPlay: (c) => c.repeat()).shimmer(
//               //       duration: const Duration(milliseconds: 1200),
//               //       color: Colors.white,
//               //     ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
import 'package:hive/hive.dart';

class SetRowItem extends StatelessWidget {
  final int index;
  final SetModel setItem;
  final ExerciseModel exercise;
  final String prevStr;
  final bool isDark;
  final Box<ExerciseModel> box;
  final int exerciseIndex;
  final List<ExerciseModel> exercises;
  final VoidCallback onTapPr;
  final VoidCallback onToggleDone;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;

  const SetRowItem({
    super.key,
    required this.index,
    required this.setItem,
    required this.exercise,
    required this.prevStr,
    required this.isDark,
    required this.box,
    required this.exerciseIndex,
    required this.exercises,
    required this.onTapPr,
    required this.onToggleDone,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapPr,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2, top: 2),
        // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          // For PR we keep outer transparent, inner Stack has gradient
          color: setItem.isPr
              ? null
              : (setItem.isDone
                  ? const Color(0xFFA3E635).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF21262D) : Colors.grey[200])),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (setItem.isPr) ...[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Background with shimmer BEHIND
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFACC15), Color(0xFFCA8A04)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: const Duration(milliseconds: 1200),
                            color: Colors.white,
                          ),
                      // 2. Text on TOP - no shimmer on it
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Est. 1RM ${(setItem.weight * (1 + (setItem.reps / 30.0))).round()} kg',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: 35,
                child: Center(
                  child: Text(
                    index == 0 ? 'W' : '$index',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: index == 0
                          ? Colors.amber
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(prevStr,
                    style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey[700],
                        fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: setItem.isDone
                        ? Colors.transparent
                        : (isDark ? const Color(0xFF30363D) : Colors.white),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: TextFormField(
                    initialValue: setItem.weight
                        .toString()
                        .replaceAll(RegExp(r'\.0$'), ''),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        border: InputBorder.none, isDense: true),
                    onChanged: (v) =>
                        onWeightChanged(double.tryParse(v) ?? 0.0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: setItem.isDone
                        ? Colors.transparent
                        : (isDark ? const Color(0xFF30363D) : Colors.white),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: TextFormField(
                    initialValue: setItem.reps.toString(),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        border: InputBorder.none, isDense: true),
                    onChanged: (v) => onRepsChanged(int.tryParse(v) ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onToggleDone,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: setItem.isDone
                        ? const Color(0xFFA3E635)
                        : (isDark ? const Color(0xFF30363D) : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: setItem.isDone ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
