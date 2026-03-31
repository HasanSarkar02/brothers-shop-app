import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';
import '../models/order_model.dart';

class OrderService {
  final Dio _dio = DioClient.instance;

  // ── Auth User Orders ───────────────────
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _dio.get('/orders');
      final data = response.data;

      final isSuccess = data['status'] == true || data['success'] == true;

      if (!isSuccess) {
        throw ApiException(data['message'] ?? 'Failed to load orders');
      }

      final orders = data['data'] as List? ?? [];
      return orders.map((o) => OrderModel.fromJson(o)).toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Guest Track Order ──────────────────
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

      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Order not found');
      }

      return OrderModel.fromJson(data['data']);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
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
        data: {'order_number': orderNumber, 'phone': phone},
      );
      final data = response.data;

      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Failed to send OTP');
      }

      return data['message'] ?? 'OTP sent';
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Verify OTP ─────────────────────────
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

      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Invalid OTP');
      }

      final orders = data['data'] as List? ?? [];
      return orders.map((o) => OrderModel.fromJson(o)).toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
