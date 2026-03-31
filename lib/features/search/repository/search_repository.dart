import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';

class SearchRepository {
  Future<List<dynamic>> fetchInstantResults(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await DioClient.instance.get(
        '/search/instant',
        queryParameters: {'q': query},
        cancelToken: cancelToken,
      );

      final data = response.data;

      if (data['success'] != true) {
        throw ApiException(data['message'] ?? 'Search failed');
      }

      return data['results'] ?? [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        rethrow;
      }
      throw ApiErrorHandler.handle(e);
    }
  }
}
