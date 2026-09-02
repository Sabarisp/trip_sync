import 'package:flutter/material.dart';
import 'package:trip_sync/theme/app_theme.dart';

class MemberAvatar extends StatelessWidget {
  final String userId;
  final String displayName;
  final bool isOnline;
  final double size;

  const MemberAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    required this.isOnline,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.colorForUser(userId);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.4,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
