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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authController = Get.find<AuthController>();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
          ),
        ),
        title: Text(
          'Register',
          style: AppTextStyles.lg.copyWith(
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
              const SizedBox(height: 20),
              CustomTextField(
                hintText: 'Full Name',
                keyboardType: TextInputType.name,
                controller: fullNameController,
                validator: Validators.name,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Obx(() => LoadingButton(
                text: 'Register',
                isLoading: authController.isLoading.value,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    authController.register(
                      emailController.text, 
                      passwordController.text, 
                      fullNameController.text
                    );
                  }
                },
              )),
              const SizedBox(height: 16),
              Text(
                'By registering, you agree to our ${AppConstants.termsConditions} and ${AppConstants.privacyPolicy}',
                style: AppTextStyles.xs.copyWith(
                  color: isDark ? AppColors.gray400 : AppColors.gray500,
                ),
                textAlign: TextAlign.center,
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