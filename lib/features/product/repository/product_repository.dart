import '../../../core/api/dio_client.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';
import '../models/product_model.dart';

class ProductRepository {
  // ── Get Products List ────────────────────────────────
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    String? category,
    String? search,
    String? sort,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await DioClient.instance.get(
        '/products',
        queryParameters: {
          'page': page,
          if (category != null) 'category': category,
          if (search != null) 'search': search,
          if (sort != null) 'sort': sort,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          'per_page': 15,
        },
      );

      final responseData = response.data;

      if (responseData['status'] == false) {
        throw ApiException(
          responseData['message'] ?? 'Failed to fetch products',
        );
      }

      final data = responseData['data'];
      return {
        'products': (data['products'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList(),
        'meta': ProductListMeta.fromJson(data['meta']),
      };
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  // ── Get Product Detail ───────────────────────────────
  Future<Map<String, dynamic>> getProductDetail(String slug) async {
    try {
      final response = await DioClient.instance.get('/products/$slug');

      final responseData = response.data;

      if (responseData['status'] == false) {
        throw ApiException(
          responseData['message'] ?? 'Failed to fetch product details',
        );
      }

      final data = responseData['data'];
      return {
        'product': ProductModel.fromJson(data['product']),
        'reviews': data['reviews'] as List,
        'star_distribution': data['star_distribution'],
        'related_products': (data['related_products'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList(),
      };
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
