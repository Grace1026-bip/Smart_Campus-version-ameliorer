import 'package:flutter/material.dart';

import '../../coeur/theme/couleurs_application.dart';
import '../../donnees/modeles/modeles_faculte.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.complaint(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return StatusBadge(
          label: status.label,
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        );
      case ComplaintStatus.inProgress:
        return StatusBadge(
          label: status.label,
          color: AppColors.info,
          icon: Icons.sync_rounded,
        );
      case ComplaintStatus.resolved:
        return StatusBadge(
          label: status.label,
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case ComplaintStatus.rejected:
        return StatusBadge(
          label: status.label,
          color: AppColors.danger,
          icon: Icons.cancel_rounded,
        );
    }
  }

  factory StatusBadge.risk(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return StatusBadge(
          label: level.label,
          color: AppColors.success,
          icon: Icons.trending_down_rounded,
        );
      case RiskLevel.medium:
        return StatusBadge(
          label: level.label,
          color: AppColors.warning,
          icon: Icons.warning_amber_rounded,
        );
      case RiskLevel.high:
        return StatusBadge(
          label: level.label,
          color: AppColors.danger,
          icon: Icons.priority_high_rounded,
        );
    }
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
