import '../../../core/api/dio_client.dart';
import '../models/product_model.dart';

class ProductRepository {
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    String? category,
    String? search,
    String? sort,
    double? minPrice,
    double? maxPrice,
  }) async {
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

    print('✅ Raw Response: ${response.data}');

    final data = response.data['data'];
    return {
      'products': (data['products'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList(),
      'meta': ProductListMeta.fromJson(data['meta']),
    };
  }

  Future<Map<String, dynamic>> getProductDetail(String slug) async {
    final response = await DioClient.instance.get('/products/$slug');
    final data = response.data['data'];
    return {
      'product': ProductModel.fromJson(data['product']),
      'reviews': data['reviews'] as List,
      'star_distribution': data['star_distribution'],
      'related_products': (data['related_products'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList(),
    };
  }
}
