import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/app_colors.dart';
import '../../constant/app_text_styles.dart';
import '../../constant/app_constants.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/custom_button.dart';
import '../../widget/loading_widget.dart';
import '../../controller/auth_controller.dart';
import '../../helper/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authController = Get.put(AuthController());
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 60),
              Text(
                'Welcome back',
                style: AppTextStyles.xxxl.copyWith(
                  color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Password',
                obscureText: _obscurePassword,
                controller: passwordController,
                validator: Validators.password,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: isDark ? AppColors.zinc500 : AppColors.zinc400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() => TextButton(
                  onPressed: authController.isLoading.value ? null : () {
                    if (emailController.text.isNotEmpty) {
                      authController.resetPassword(emailController.text);
                    } else {
                      Get.snackbar('Error', 'Please enter your email first');
                    }
                  },
                  child: Text(
                    AppConstants.forgotPassword,
                    style: AppTextStyles.sm.copyWith(
                      color: authController.isLoading.value 
                        ? AppColors.gray400 
                        : AppColors.primary,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              Obx(() => LoadingButton(
                text: 'Log in',
                isLoading: authController.isLoading.value,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    authController.login(emailController.text, passwordController.text);
                  }
                },
              )),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: AppTextStyles.sm.copyWith(
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/register'),
                    child: Text(
                      'Sign up',
                      style: AppTextStyles.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}