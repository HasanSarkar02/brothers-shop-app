import '../../../core/api/dio_client.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';
import '../models/cart_model.dart';

class CartRepository {
  // ── Get Cart ───────────────────────────────────────
  Future<CartSummary> getCart() async {
    try {
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
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Add to Cart ────────────────────────────────────
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

      final data = response.data;
      if (data['status'] != true) {
        throw ApiException(data['message'] ?? 'Failed to add to cart');
      }

      return data;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Update Cart ────────────────────────────────────
  Future<Map<String, dynamic>> updateCart({
    required int cartId,
    required int quantity,
  }) async {
    try {
      final response = await DioClient.instance.patch(
        '/cart/$cartId',
        data: {'quantity': quantity},
      );

      if (response.data['status'] != true) {
        throw ApiException(response.data['message'] ?? 'Failed to update cart');
      }
      return response.data;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Remove From Cart ───────────────────────────────
  Future<void> removeFromCart(int cartId) async {
    try {
      await DioClient.instance.delete('/cart/$cartId');
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Clear Cart ─────────────────────────────────────
  Future<void> clearCart() async {
    try {
      await DioClient.instance.delete('/cart/clear');
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
