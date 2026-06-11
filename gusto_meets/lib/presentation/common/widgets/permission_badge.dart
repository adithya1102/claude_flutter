import 'package:flutter/material.dart';

class PermissionBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool allowed;
  final Color color;

  const PermissionBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.allowed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: allowed ? color.withAlpha(26) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: allowed ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: allowed ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
