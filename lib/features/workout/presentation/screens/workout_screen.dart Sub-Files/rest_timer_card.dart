import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFA3E635).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: restSecondsRemaining / 90,
                  backgroundColor:
                      isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFA3E635)),
                  strokeWidth: 4,
                ),
              ),
              Text(
                '${(restSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(restSecondsRemaining % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest timer',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(activeRestInfo,
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis),
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
