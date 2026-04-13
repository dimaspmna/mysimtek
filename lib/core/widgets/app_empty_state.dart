import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRefresh;

  const AppEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRefresh,
                child: const Text(
                  'Coba lagi',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
