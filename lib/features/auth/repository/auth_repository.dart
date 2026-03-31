import '../../../core/api/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/auth_model.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';

class AuthRepository {
  // ── Login ──────────────────────────────
  Future<AuthUser> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final guestSession = await LocalStorage.getGuestSessionId();

      final response = await DioClient.instance.post(
        '/login',
        data: {
          'identifier': identifier,
          'password': password,
          'guest_session_id': guestSession,
        },
      );

      final data = response.data;
      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Login failed');
      }

      final token = data['data']['token'] as String;
      final user = AuthUser.fromJson(data['data']['user']);

      await LocalStorage.saveToken(token);
      await LocalStorage.saveUser(data['data']['user']);

      return user;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Register ───────────────────────────
  Future<AuthUser> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final guestSession = await LocalStorage.getGuestSessionId();

      final response = await DioClient.instance.post(
        '/register',
        data: {
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'guest_session_id': guestSession,
        },
      );

      final data = response.data;
      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Registration failed');
      }

      final token = data['data']['token'] as String;
      final user = AuthUser.fromJson(data['data']['user']);

      await LocalStorage.saveToken(token);
      await LocalStorage.saveUser(data['data']['user']);

      return user;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Social Login ───────────────────────
  Future<AuthUser> socialLogin({
    required String provider,
    required String accessToken,
  }) async {
    try {
      final guestSession = await LocalStorage.getGuestSessionId();

      final response = await DioClient.instance.post(
        '/social-login',
        data: {
          'provider': provider,
          'access_token': accessToken,
          'guest_session_id': guestSession,
        },
      );

      final data = response.data;
      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Social login failed');
      }

      final token = data['data']['token'] as String;
      final user = AuthUser.fromJson(data['data']['user']);

      await LocalStorage.saveToken(token);
      await LocalStorage.saveUser(data['data']['user']);

      return user;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Logout ─────────────────────────────
  Future<void> logout() async {
    try {
      await DioClient.instance.post('/logout');
    } catch (_) {}
    await LocalStorage.deleteToken();
    await LocalStorage.clearUser();
  }

  // ── Get current user ───────────────────
  Future<AuthUser?> getMe() async {
    try {
      final response = await DioClient.instance.get('/me');
      final data = response.data;
      if (data['status'] == true) {
        return AuthUser.fromJson(data['data']['user']);
      }
    } catch (_) {}
    return null;
  }
}
