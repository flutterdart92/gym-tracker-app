import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeletonLoader extends StatelessWidget {
  final bool isDark;
  const AppSkeletonLoader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF21262D) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF30363D) : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => Container(
          height: 75,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
