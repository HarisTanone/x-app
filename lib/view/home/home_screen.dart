import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/app_colors.dart';
import '../../constant/app_text_styles.dart';
import '../../controller/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authController = Get.find<AuthController>();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dating App',
          style: AppTextStyles.lg.copyWith(
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => authController.logout(),
            icon: Icon(
              Icons.logout,
              color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to Dating App!',
          style: AppTextStyles.xxl.copyWith(
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
          ),
        ),
      ),
    );
  }
}