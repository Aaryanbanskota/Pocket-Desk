import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging/app_logger.dart';

class SupabaseAuthService {
  static const String supabaseUrl = 'https://bixxlqagljrxerijyezw.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpeHhscWFnbGpyeGVyaWp5ZXp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NzAzNzMsImV4cCI6MjEwNjM0NjM3M30.AoekEPshl4YnAUjiYfdD5BhRoyLmXvpY665JZXsmp2M';

  /// Sign up a user with email and password via Supabase Auth REST API.
  /// Triggers Supabase to dispatch a confirmation email to [email].
  static Future<({bool success, String? userId, String? errorMessage})> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/auth/v1/signup');
      final response = await http.post(
        uri,
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final id = body['id'] as String? ?? body['user']?['id'] as String?;
        AppLogger.i('Supabase Auth signUp successful for $email, userId: $id',
            tag: 'SupabaseAuthService');
        return (success: true, userId: id, errorMessage: null);
      } else {
        final msg = body['msg'] ?? body['message'] ?? body['error_description'] ?? 'Registration failed';
        AppLogger.w('Supabase Auth signUp failed: $msg', tag: 'SupabaseAuthService');
        return (success: false, userId: null, errorMessage: msg.toString());
      }
    } catch (e, st) {
      AppLogger.e('Supabase Auth signUp exception',
          tag: 'SupabaseAuthService', error: e, st: st);
      return (success: false, userId: null, errorMessage: e.toString());
    }
  }

  /// Create a record in public.pro_requests when a user chooses the Pro Plan.
  static Future<bool> createProRequest({
    required String email,
    String? userId,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/pro_requests');
      final response = await http.post(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'user_id': userId,
          'email': email,
          'plan': 'pro',
          'status': 'pending',
          'requested_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.i('pro_requests row inserted successfully for $email',
            tag: 'SupabaseAuthService');
        return true;
      } else {
        AppLogger.w(
            'Failed to insert pro_requests row: ${response.statusCode} - ${response.body}',
            tag: 'SupabaseAuthService');
        return false;
      }
    } catch (e, st) {
      AppLogger.e('Exception inserting pro_requests row',
          tag: 'SupabaseAuthService', error: e, st: st);
      return false;
    }
  }

  /// Wipe user's cloud data and pending requests when account is deleted.
  static Future<bool> deleteUserData({required String email}) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/pro_requests?email=eq.$email');
      final response = await http.delete(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.i('Cloud pro_requests data wiped for $email',
            tag: 'SupabaseAuthService');
        return true;
      } else {
        AppLogger.w(
            'Failed to delete cloud pro_requests: ${response.statusCode}',
            tag: 'SupabaseAuthService');
        return false;
      }
    } catch (e, st) {
      AppLogger.e('Exception wiping user cloud data',
          tag: 'SupabaseAuthService', error: e, st: st);
      return false;
    }
  }
}
