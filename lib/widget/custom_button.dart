import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import '../constant/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;

  const CustomButton({
    super.key,
    required this.text,
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary 
            ? (isDark ? AppColors.slate700 : AppColors.slate200)
            : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.base.copyWith(
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