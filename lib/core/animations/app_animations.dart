import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';

// STEP 1: APP LAUNCH - Stagger helper
class AppLaunchAnimationWrapper extends StatelessWidget {
  final Widget logo;
  final List<Widget> children;
  const AppLaunchAnimationWrapper(
      {super.key, required this.logo, required this.children});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        reduce
            ? logo
            : logo
                .animate()
                .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 650.ms,
                    curve: Curves.easeOutCubic)
                .fadeIn(duration: 600.ms),
        ...children.asMap().entries.map((e) {
          if (reduce) return e.value;
          return e.value
              .animate()
              .fadeIn(delay: (120 + e.key * 40).ms, duration: 380.ms)
              .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: (120 + e.key * 40).ms,
                  duration: 380.ms,
                  curve: Curves.easeOutCubic);
        }),
      ],
    );
  }
}

// STEP 2: TAB SWITCH - 300ms Fade-Through
// class FadeThroughTabSwitcher extends StatelessWidget {
//   final int selectedIndex;
//   final List<Widget> pages;
//   const FadeThroughTabSwitcher(
//       {super.key, required this.selectedIndex, required this.pages});

//   @override
//   Widget build(BuildContext context) {
//     final reduce = MediaQuery.of(context).disableAnimations;
//     return PageTransitionSwitcher(
//       duration: const Duration(milliseconds: 300),
//       reverse: false,
//       transitionBuilder: (child, primary, secondary) {
//         if (reduce) return child;
//         return FadeThroughTransition(
//           animation: primary,
//           secondaryAnimation: secondary,
//           fillColor: Theme.of(context).scaffoldBackgroundColor,
//           child: child,
//         );
//       },
//       child: KeyedSubtree(
//         key: ValueKey(selectedIndex),
//         child: pages[selectedIndex],
//       ),
//     );
//   }
// }

class FadeThroughTabSwitcher extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> pages;
  const FadeThroughTabSwitcher(
      {super.key, required this.selectedIndex, required this.pages});

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 300),
      reverse: false,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(selectedIndex),
        child: pages[selectedIndex],
      ),
    );
  }
}

// STEP 3: FAB -> ADD SHEET - 350ms Container Transform
class MorphingFabToSheet extends StatelessWidget {
  final Widget sheetContent;
  final Color fabColor;
  final IconData icon;
  final Color iconColor;
  const MorphingFabToSheet({
    super.key,
    required this.sheetContent,
    required this.fabColor,
    this.icon = Icons.add,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      return FloatingActionButton(
        backgroundColor: fabColor,
        onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => sheetContent),
        child: Icon(icon, color: iconColor),
      );
    }
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 350),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 6,
      openElevation: 0,
      closedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      openShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      closedColor: fabColor,
      openColor: isDark ? const Color(0xFF131313) : Colors.white,
      closedBuilder: (context, openContainer) {
        return SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            backgroundColor: fabColor,
            elevation: 0,
            onPressed: openContainer,
            child: Icon(icon, color: iconColor),
          ),
        );
      },
      openBuilder: (context, _) => sheetContent,
    );
  }
}

// THIS IS THE MISSING EXTENSION - THIS FIXES YOUR ERROR
// extension StaggerListExtension on List<Widget> {
//   List<Widget> withStagger(BuildContext context,
//       {int baseDelay = 100, int step = 40}) {
//     final reduce = MediaQuery.of(context).disableAnimations;
//     if (reduce) return this;
//     return asMap().entries.map((e) {
//       return e.value
//           .animate()
//           .fadeIn(delay: (baseDelay + e.key * step).ms, duration: 350.ms)
//           .slideY(
//               begin: 0.12,
//               end: 0,
//               delay: (baseDelay + e.key * step).ms,
//               duration: 350.ms,
//               curve: Curves.easeOutCubic);
//     }).toList();
//   }
// }

extension StaggerExtension on List<Widget> {
  List<Widget> withStagger(BuildContext context,
      {int baseDelay = 80, int step = 40, int duration = 400}) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) return this;
    return asMap().entries.map((e) {
      final delay = baseDelay + (e.key * step);
      return e.value
          .animate()
          .fadeIn(
              delay: delay.ms,
              duration: duration.ms,
              curve: Curves.easeOutCubic)
          .slideY(
              begin: 0.20,
              end: 0,
              delay: delay.ms,
              duration: duration.ms,
              curve: Curves.easeOutCubic);
    }).toList();
  }
}
