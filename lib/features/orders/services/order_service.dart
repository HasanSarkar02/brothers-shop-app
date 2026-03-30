import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/order_model.dart';

class OrderService {
  final Dio _dio = DioClient.instance;

  // ── Auth User Orders ───────────────────
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _dio.get('/orders');
      final data = response.data;

      final isSuccess = data['status'] == true || data['success'] == true;

      if (isSuccess) {
        final orders = data['data'] as List? ?? [];
        return orders.map((o) => OrderModel.fromJson(o)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load orders');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Guest Track Order ──────────────────
  // Direct track — order number + phone
  Future<OrderModel> trackGuestOrder({
    required String orderNumber,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/track',
        data: {'order_number': orderNumber, 'phone': phone},
      );
      final data = response.data;

      if (data['status'] == true) {
        return OrderModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Order not found');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Send OTP ───────────────────────────
  Future<String> sendOtp({
    required String orderNumber,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/send-otp',
        data: {
          'order_number': orderNumber, // Laravel এ না থাকলেও problem নেই
          'phone': phone,
        },
      );
      final data = response.data;

      if (data['status'] == true) {
        return data['message'] ?? 'OTP sent';
      } else {
        throw Exception(data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Verify OTP ─────────────────────────
  // Returns List<OrderModel> — সব orders দেখাবে
  Future<List<OrderModel>> verifyOtp({
    required String orderNumber,
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/verify-otp',
        data: {'order_number': orderNumber, 'phone': phone, 'otp': otp},
      );
      final data = response.data;

      if (data['status'] == true) {
        // Laravel এ List return করছে
        final orders = data['data'] as List? ?? [];
        return orders.map((o) => OrderModel.fromJson(o)).toList();
      } else {
        throw Exception(data['message'] ?? 'Invalid OTP');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return Exception(data['message'].toString());
      }
      switch (e.response!.statusCode) {
        case 400:
          return Exception(data['message'] ?? 'Bad request');
        case 401:
          return Exception('Please login to continue.');
        case 404:
          return Exception('Order not found. Check order number and phone.');
        case 422:
          return Exception(data['message'] ?? 'Invalid input');
        case 429:
          return Exception('Too many attempts. Request a new OTP.');
        case 500:
          return Exception('Server error. Please try again.');
        default:
          return Exception('Something went wrong (${e.response!.statusCode})');
      }
    }
    return Exception('Network error. Check your connection.');
  }
}
