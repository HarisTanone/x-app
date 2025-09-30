import 'package:flutter/material.dart';
import '../constant/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final String text;
  final String loadingText;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isSecondary;

  const LoadingButton({
    super.key,
    required this.text,
    this.loadingText = 'Loading...',
    required this.isLoading,
    this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary 
            ? (isDark ? AppColors.slate700 : AppColors.slate200)
            : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LoadingWidget(size: 16),
                const SizedBox(width: 8),
                Text(
                  loadingText,
                  style: TextStyle(
                    color: isSecondary 
                      ? (isDark ? AppColors.foregroundDark : AppColors.foregroundLight)
                      : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                color: isSecondary 
                  ? (isDark ? AppColors.foregroundDark : AppColors.foregroundLight)
                  : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}