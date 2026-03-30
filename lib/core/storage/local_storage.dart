import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();

  // ── Token ──────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // ── Guest Session ──────────────────────────────
  static Future<String> getGuestSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('guest_session_id');
    if (sessionId == null) {
      sessionId = const Uuid().v4();
      await prefs.setString('guest_session_id', sessionId);
    }
    return sessionId;
  }

  // ── Wishlist (local) ───────────────────────────
  static Future<List<int>> getLocalWishlistIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('wishlist_ids') ?? [];
    return ids.map(int.parse).toList();
  }

  static Future<void> saveLocalWishlistIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'wishlist_ids',
      ids.map((id) => id.toString()).toList(),
    );
  }

  // ── User ───────────────────────────────────────
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setString('user_phone', user['phone'] ?? '');
    await prefs.setString('user_avatar', user['avatar'] ?? '');
  }

  static Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'phone': prefs.getString('user_phone') ?? '',
      'avatar': prefs.getString('user_avatar') ?? '',
    };
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_avatar');
  }
}
