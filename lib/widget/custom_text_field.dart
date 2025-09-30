import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import '../constant/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(
          color: isDark ? AppColors.zinc500 : AppColors.zinc400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.stone800 : AppColors.stone600,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      style: AppTextStyles.base.copyWith(
        color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
      ),
    );
  }
}