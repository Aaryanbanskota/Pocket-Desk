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
    String? username,
    String? displayName,
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
          'data': {
            if (username != null) 'username': username,
            if (displayName != null) 'display_name': displayName,
          }
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final id = body['id'] as String? ?? body['user']?['id'] as String?;
        AppLogger.i('Supabase Auth signUp successful for $email, userId: $id',
            tag: 'SupabaseAuthService');
        if (id != null) {
          await upsertProfile(
            userId: id,
            email: email,
            username: username ?? email.split('@').first,
            displayName: displayName,
          );
        }
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

  /// Create or update user profile identity record in public.profiles table.
  static Future<bool> upsertProfile({
    required String userId,
    required String email,
    required String username,
    String? displayName,
    String accountType = 'cloud',
    String cloudPlan = 'free',
    bool isProActivated = false,
    bool isActive = true,
  }) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      final uri = Uri.parse('$supabaseUrl/rest/v1/profiles');
      final response = await http.post(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'id': userId,
          'email': email,
          'username': username,
          'display_name': displayName ?? username,
          'account_type': accountType,
          'account_plan': cloudPlan,
          'cloud_plan': cloudPlan,
          'is_pro_activated': isProActivated || cloudPlan == 'pro',
          'is_active': isActive,
          'updated_at': nowStr,
          'created_at': nowStr,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.i('User profile identity upserted in Supabase profiles for $email (ID: $userId)',
            tag: 'SupabaseAuthService');
        return true;
      } else {
        AppLogger.w(
            'Failed to upsert profile: ${response.statusCode} - ${response.body}',
            tag: 'SupabaseAuthService');
        return false;
      }
    } catch (e, st) {
      AppLogger.e('Exception upserting profile in Supabase',
          tag: 'SupabaseAuthService', error: e, st: st);
      return false;
    }
  }

  /// Syncs and fetches profile status & Pro plan activation state from Supabase backend.
  static Future<({
    bool found,
    String? userId,
    String? email,
    String? username,
    String? displayName,
    String? accountType,
    String? cloudPlan,
    bool isProActive,
    bool isActive,
  })> syncProfileFromSupabase({required String email}) async {
    try {
      final uri = Uri.parse('$supabaseUrl/rest/v1/profiles?email=eq.$email&select=*');
      final response = await http.get(
        uri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      bool isProActive = false;
      bool isActive = true;
      String? id;
      String? username;
      String? displayName;
      String? accountType;
      String? cloudPlan;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final data = list.first as Map<String, dynamic>;
          id = data['id']?.toString();
          username = data['username']?.toString();
          displayName = data['display_name']?.toString();
          accountType = data['account_type']?.toString();
          cloudPlan = (data['account_plan'] ?? data['cloud_plan'])?.toString() ?? 'free';
          isActive = data['is_active'] != false;
          if (cloudPlan == 'pro' && isActive) {
            isProActive = true;
          }
        }
      }

      // Check pro_requests table for status
      final proUri = Uri.parse('$supabaseUrl/rest/v1/pro_requests?email=eq.$email&select=*');
      final proResponse = await http.get(
        proUri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      if (proResponse.statusCode >= 200 && proResponse.statusCode < 300) {
        final proList = jsonDecode(proResponse.body) as List<dynamic>;
        if (proList.isNotEmpty) {
          final proData = proList.first as Map<String, dynamic>;
          final status = proData['status']?.toString();
          if (status == 'approved' || status == 'active') {
            isProActive = true;
            cloudPlan = 'pro';
          }
        }
      }

      return (
        found: id != null,
        userId: id,
        email: email,
        username: username,
        displayName: displayName,
        accountType: accountType,
        cloudPlan: cloudPlan,
        isProActive: isProActive,
        isActive: isActive,
      );
    } catch (e, st) {
      AppLogger.e('Exception syncing profile from Supabase',
          tag: 'SupabaseAuthService', error: e, st: st);
      return (
        found: false,
        userId: null,
        email: email,
        username: null,
        displayName: null,
        accountType: null,
        cloudPlan: null,
        isProActive: false,
        isActive: true,
      );
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

  /// Wipe user's cloud data, profile, and pending requests when account is deleted.
  static Future<bool> deleteUserData({required String email}) async {
    try {
      // 1. Delete pro_requests
      final proUri = Uri.parse('$supabaseUrl/rest/v1/pro_requests?email=eq.$email');
      await http.delete(
        proUri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      // 2. Delete public.profiles row
      final profileUri = Uri.parse('$supabaseUrl/rest/v1/profiles?email=eq.$email');
      final response = await http.delete(
        profileUri,
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.i('Cloud user profile & requests data wiped for $email',
            tag: 'SupabaseAuthService');
        return true;
      } else {
        AppLogger.w(
            'Failed to delete cloud profile: ${response.statusCode}',
            tag: 'SupabaseAuthService');
        return false;
      }
    } catch (e, st) {
      AppLogger.e('Exception wiping user cloud data',
          tag: 'SupabaseAuthService', error: e, st: st);
      return false;
    }
  }

  /// Sign in a user with email and password via Supabase Auth REST API.
  static Future<({bool success, String? userId, String? token, String? errorMessage})> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');
      final response = await http.post(
        uri,
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final id = body['user']?['id'] as String? ?? body['id'] as String?;
        final accessToken = body['access_token'] as String?;
        AppLogger.i('Supabase Auth signIn successful for $email, userId: $id',
            tag: 'SupabaseAuthService');
        return (success: true, userId: id, token: accessToken, errorMessage: null);
      } else {
        final msg = body['error_description'] ?? body['msg'] ?? body['message'] ?? 'Login failed';
        AppLogger.w('Supabase Auth signIn failed: $msg', tag: 'SupabaseAuthService');
        return (success: false, userId: null, token: null, errorMessage: msg.toString());
      }
    } catch (e, st) {
      AppLogger.e('Supabase Auth signIn exception',
          tag: 'SupabaseAuthService', error: e, st: st);
      return (success: false, userId: null, token: null, errorMessage: e.toString());
    }
  }
}
