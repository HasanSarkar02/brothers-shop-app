import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';
import '../models/checkout_model.dart';

class CheckoutService {
  final Dio _dio = DioClient.instance;

  // ── GET /checkout — Summary fetch ──────────────
  Future<CheckoutSummaryModel> getCheckoutSummary() async {
    try {
      final response = await _dio.get('/checkout');
      final data = response.data;

      if (data['status'] != true) {
        throw ApiException(
          data['message'] ?? 'Failed to load checkout summary',
        );
      }

      return CheckoutSummaryModel.fromJson(data['data']);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
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

      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Failed to place order');
      }

      return OrderResponseModel.fromJson(data['data']);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── GET /checkout/confirmation/{orderNumber} ───
  Future<Map<String, dynamic>> getOrderConfirmation(String orderNumber) async {
    try {
      final response = await _dio.get('/checkout/confirmation/$orderNumber');
      final data = response.data;

      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Order not found');
      }

      return data['data'];
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
