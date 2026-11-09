import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RestTimerCard extends StatelessWidget {
  final bool isDark;
  final int restSecondsRemaining;
  final String activeRestInfo;
  final VoidCallback onMinus15;
  final VoidCallback onPlus15;
  final VoidCallback onSkip;

  const RestTimerCard({
    super.key,
    required this.isDark,
    required this.restSecondsRemaining,
    required this.activeRestInfo,
    required this.onMinus15,
    required this.onPlus15,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // Trigger vibration and pulse during the final 3 seconds
    if (restSecondsRemaining <= 10 && restSecondsRemaining > 0) {
      HapticFeedback.heavyImpact();
    }

    final isUrgent = restSecondsRemaining <= 10;
    const lime = Color(0xFFA3E635);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.redAccent : lime.withValues(alpha: 0.4),
          width: isUrgent ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Circular Countdown with CustomPainter / Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: restSecondsRemaining / 90,
                  backgroundColor:
                      isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? Colors.redAccent : lime,
                  ),
                  strokeWidth: 4,
                ),
              ),
              Text(
                '${(restSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(restSecondsRemaining % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ).animate(target: isUrgent ? 1 : 0).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 400.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? 'Rest ending soon!' : 'Rest timer',
                  style: TextStyle(
                    color: isUrgent
                        ? Colors.redAccent
                        : (isDark ? Colors.white : Colors.black87),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeRestInfo,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(36, 26),
                      ),
                      onPressed: onMinus15,
                      child: Text('-15s',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 10)),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: const Size(36, 26),
                      ),
                      onPressed: onPlus15,
                      child: Text('+15s',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 10)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 0),
                        minimumSize: const Size(32, 26),
                      ),
                      onPressed: onSkip,
                      child: const Text('Skip',
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
