import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/checkout_model.dart';

class CheckoutService {
  final Dio _dio = DioClient.instance;

  // ── GET /checkout — Summary fetch ──────────────
  Future<CheckoutSummaryModel> getCheckoutSummary() async {
    try {
      final response = await _dio.get('/checkout');
      final data = response.data;

      if (data['status'] == true) {
        return CheckoutSummaryModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load checkout summary');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Your cart is empty.');
      }
      throw Exception('Network error. Please check your connection.');
    }
  }

  // ── POST /checkout/place-order ─────────────────
  Future<OrderResponseModel> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post(
        '/checkout/place-order',
        data: orderData,
      );
      final data = response.data;

      if (data['status'] == true) {
        return OrderResponseModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to place order');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Order failed.');
      }
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          throw Exception(
            firstError is List ? firstError.first : firstError.toString(),
          );
        }
        throw Exception('Validation error. Please check your inputs.');
      }
      throw Exception('Network error. Please try again.');
    }
  }

  // ── GET /checkout/confirmation/{orderNumber} ───
  Future<Map<String, dynamic>> getOrderConfirmation(String orderNumber) async {
    try {
      final response = await _dio.get('/checkout/confirmation/$orderNumber');
      final data = response.data;

      if (data['status'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Order not found');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Unauthorized to view this order.');
      }
      throw Exception('Network error. Please try again.');
    }
  }
}
