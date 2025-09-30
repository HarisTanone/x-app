import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/app_colors.dart';
import '../constant/app_text_styles.dart';

class CustomSnackbar {
  static void success(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void error(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: AppColors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  static void info(String message) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }
}