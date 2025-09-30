import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://nkcftpwmggtlzmajpzet.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rY2Z0cHdtZ2d0bHptYWpwemV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyMDE5ODMsImV4cCI6MjA3NDc3Nzk4M30.Bm8aOFYEGvUbkgmqeiJhteMjKNNhnFsdkdbN4H0VJRA';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: _url,
        anonKey: _anonKey,
        debug: false,
      );
    } catch (e) {
      print('Supabase init error: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
  static RealtimeClient get realtime => client.realtime;
}