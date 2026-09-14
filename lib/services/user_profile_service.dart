import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Reads and writes the on-device [UserProfile].
///
/// There is no account backend behind sign up / sign in, so this local
/// record — persisted via [SharedPreferences] — is the only place the app's
/// notion of "the current user" lives.
class UserProfileService {
  UserProfileService._internal();

  static final UserProfileService instance = UserProfileService._internal();

  static const String _prefsKey = 'user_profile_v1';
  static const String _loggedInKey = 'user_logged_in_v1';

  /// Whether the app should treat the stored profile as the active session.
  ///
  /// A profile can exist on disk while the user is logged out (they signed
  /// out but didn't delete their profile), so this is tracked separately
  /// from whether [load] returns data.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  Future<UserProfile?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      return UserProfile.fromJson(decoded);
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      return null;
    }
  }

  Future<void> save(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Failed to save user profile: $e');
    }
  }

  /// Deletes the stored profile and its photo file, if any.
  Future<void> clear() async {
    try {
      final existing = await load();
      if (existing?.avatarPath != null) {
        final file = File(existing!.avatarPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.setBool(_loggedInKey, false);
    } catch (e) {
      debugPrint('Failed to clear user profile: $e');
    }
  }
}
