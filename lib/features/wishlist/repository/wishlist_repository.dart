import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../product/models/product_model.dart';

class WishlistRepository {
  final _dio = DioClient.instance;

  // ── Get Wishlist (Logged In Users) ─────────────────
  Future<List<ProductModel>> getWishlist() async {
    try {
      final response = await _dio.get('/wishlist');
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List data = response.data['data']['items'] ?? [];
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load wishlist: $e');
    }
  }

  // ── Get Guest Items (Not Logged In Users) ──────────
  Future<List<ProductModel>> getGuestWishlistItems(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _dio.post(
        '/wishlist/guest-items',
        data: {'ids': ids},
      );
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List data = response.data['data']['items'] ?? [];
        return data.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load guest wishlist: $e');
    }
  }

  // ── Toggle Wishlist (Logged In Users) ──────────────
  Future<Map<String, dynamic>> toggleWishlist(int productId) async {
    try {
      final response = await _dio.post(
        '/wishlist/toggle',
        data: {'product_id': productId},
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        print('🔴 API Error Status: ${e.response?.statusCode}');
        print('🔴 API Error Data: ${e.response?.data}');
      }
      throw Exception('Failed to update wishlist: $e');
    }
  }

  // ── Sync Guest Wishlist on Login ───────────────────
  Future<void> syncGuestWishlist(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      await _dio.post('/wishlist/merge', data: {'product_ids': ids});
    } catch (e) {
      print('🔴 Failed to sync wishlist: $e');
    }
  }
}
