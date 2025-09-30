import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/supabase_service.dart';
import '../widget/custom_snackbar.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  void _checkAuthState() {
    final session = SupabaseService.auth.currentSession;
    isLoggedIn.value = session != null;
    
    // Listen to auth state changes
    SupabaseService.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      isLoggedIn.value = session != null;
    });
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        isLoggedIn.value = true;
        CustomSnackbar.success('Login successful');
        Get.offAllNamed('/home');
      }
    } on AuthException catch (e) {
      CustomSnackbar.error(e.message);
    } catch (e) {
      CustomSnackbar.error('An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      isLoading.value = true;
      
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        CustomSnackbar.success('Registration successful. Please check your email for verification.');
        Get.back();
      }
    } on AuthException catch (e) {
      CustomSnackbar.error(e.message);
    } catch (e) {
      CustomSnackbar.error('An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseService.auth.signOut();
      isLoggedIn.value = false;
      CustomSnackbar.success('Logged out successfully');
      Get.offAllNamed('/login');
    } catch (e) {
      CustomSnackbar.error('Failed to logout');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      
      await SupabaseService.auth.resetPasswordForEmail(email);
      CustomSnackbar.success('Password reset email sent');
    } on AuthException catch (e) {
      CustomSnackbar.error(e.message);
    } catch (e) {
      CustomSnackbar.error('An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }
}