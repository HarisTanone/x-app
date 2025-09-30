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

  Future<void> register(String email, String password, String fullName, String phone, String dateOfBirth, String gender) async {
    try {
      isLoading.value = true;
      
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create profile after successful auth signup
        await SupabaseService.client.from('profiles').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'date_of_birth': dateOfBirth,
          'gender': gender.toLowerCase(),
          'bio': null,
          'location': null,
          'interests': [],
          'photos': [],
          'is_verified': false,
          'is_premium': false,
          'last_active': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        CustomSnackbar.success('Registration successful!');
        Get.back();
      }
    } on AuthException catch (e) {
      CustomSnackbar.error(e.message);
    } catch (e) {
      print('Registration error: $e');
      CustomSnackbar.error('Registration failed: ${e.toString()}');
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