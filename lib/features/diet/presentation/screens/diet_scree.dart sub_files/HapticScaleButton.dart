// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:gym_tracker_app/core/theme/app_colors.dart';

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
