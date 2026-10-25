import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color dotColor;

    switch (s) {
      case 'online':
      case 'succeeded':
        bgColor = isDark ? const Color(0xFF21382E) : const Color(0xFFE5F5ED);
        fgColor = isDark ? const Color(0xFFA6E1C8) : const Color(0xFF2A664B);
        dotColor = const Color(0xFF34C77B);
        break;
      case 'pending':
      case 'sent':
      case 'accepted':
        bgColor = isDark ? const Color(0xFF3A3120) : const Color(0xFFFCF3DF);
        fgColor = isDark ? const Color(0xFFF3D088) : const Color(0xFF805B17);
        dotColor = const Color(0xFFE5A922);
        break;
      case 'failed':
        bgColor = isDark ? const Color(0xFF3C2327) : const Color(0xFFFCEBEC);
        fgColor = isDark ? const Color(0xFFF2A7AA) : const Color(0xFF94383C);
        dotColor = const Color(0xFFE56B6F);
        break;
      default:
        bgColor = isDark ? const Color(0xFF2B2936) : const Color(0xFFF1EFF7);
        fgColor = isDark ? const Color(0xFFA8A3BC) : const Color(0xFF6A647E);
        dotColor = const Color(0xFF9B95B0);
        break;
    }

    final label = s.isEmpty
        ? 'Unknown'
        : '${s[0].toUpperCase()}${s.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
