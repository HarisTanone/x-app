import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'service/supabase_service.dart';
import 'constant/app_themes.dart';
import 'view/auth/login_screen.dart';
import 'view/home/home_screen.dart';
import 'view/auth/register_screen.dart';
import 'controller/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('Supabase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    
    return GetMaterialApp(
      title: 'myapp',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
      home: Obx(() => authController.isLoggedIn.value 
        ? const HomeScreen() 
        : const LoginScreen()),
    );
  }
}