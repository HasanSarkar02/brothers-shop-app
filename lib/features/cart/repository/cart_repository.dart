import '../../../core/api/dio_client.dart';
import '../models/cart_model.dart';
import 'package:dio/dio.dart';

class CartRepository {
  Future<CartSummary> getCart() async {
    final response = await DioClient.instance.get('/cart');
    final data = response.data['data'];

    final items = (data['items'] as List)
        .map((e) => CartModel.fromJson(e))
        .toList();

    return CartSummary(
      items: items,
      cartCount: data['cart_count'] ?? 0,
      cartTotal: (data['cart_total'] as num?)?.toDouble() ?? 0.0,
      savings: (data['savings'] as num?)?.toDouble() ?? 0.0,
      isEmpty: data['is_empty'] ?? items.isEmpty,
    );
  }

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    try {
      final response = await DioClient.instance.post(
        '/cart/add',
        data: {
          'product_id': productId,
          if (variantId != null) 'variant_id': variantId,
          'quantity': quantity,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 422) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCart({
    required int cartId,
    required int quantity,
  }) async {
    final response = await DioClient.instance.patch(
      '/cart/$cartId',
      data: {'quantity': quantity},
    );
    return response.data;
  }

  Future<void> removeFromCart(int cartId) async {
    await DioClient.instance.delete('/cart/$cartId');
  }

  Future<void> clearCart() async {
    await DioClient.instance.delete('/cart/clear');
  }
}
