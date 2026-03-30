import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/local_storage.dart';

class ProfileService {
  final Dio _dio = DioClient.instance;

  // ═══════════════════════════════════════
  // Get profile (auth only)
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      final data = response.data;

      if (data['status'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load profile');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  // Update profile
  // ═══════════════════════════════════════
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/profile/update', data: data);
      final res = response.data;

      if (res['status'] == true) {
        return res['data'];
      } else {
        throw Exception(res['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  // Upload avatar
  // ═══════════════════════════════════════
  Future<String> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post('/profile/avatar', data: formData);
      final res = response.data;
      if (res['success'] == true) {
        return res['url'] ?? '';
      } else {
        throw Exception(res['message'] ?? 'Failed to upload avatar');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // ═══════════════════════════════════════
  // Change password
  // ═══════════════════════════════════════
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/profile/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      final res = response.data;

      if (res['status'] == true) {
        return res['message'] ?? 'Password changed successfully';
      } else {
        throw Exception(res['message'] ?? 'Failed to change password');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  // Logout
  // ═══════════════════════════════════════
  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException catch (e) {
      // Even if server fails, we clear local data
      debugPrint('Logout API error: ${e.message}');
    }
  }

  // ═══════════════════════════════════════
  // Fetch pages (about, privacy, terms)
  // ═══════════════════════════════════════
  Future<String> getPage(String slug) async {
    try {
      final response = await _dio.get('/pages/$slug');
      final data = response.data;

      if (data['status'] == true) {
        return data['data']['content'] ?? '';
      } else {
        throw Exception(data['message'] ?? 'Page not found');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════
  // Send contact form
  // ═══════════════════════════════════════
  Future<String> sendContact({
    required String name,
    required String phone,
    String? email,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/contact',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'message': message,
        },
      );
      final res = response.data;

      if (res['status'] == true) {
        return res['message'] ?? 'Message sent successfully';
      } else {
        throw Exception(res['message'] ?? 'Failed to send message');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return Exception(data['message'].toString());
      }
      switch (e.response!.statusCode) {
        case 401:
          return Exception('Session expired. Please login again.');
        case 422:
          if (data is Map<String, dynamic> && data['errors'] != null) {
            final errors = data['errors'] as Map<String, dynamic>;
            final first = errors.values.first;
            return Exception(
              first is List ? first.first.toString() : first.toString(),
            );
          }
          return Exception('Validation error.');
        case 400:
          return Exception(data['message'] ?? 'Bad request');
        case 500:
          return Exception('Server error. Please try again.');
        default:
          return Exception('Something went wrong.');
      }
    }
    return Exception('Network error. Please check your connection.');
  }
}
