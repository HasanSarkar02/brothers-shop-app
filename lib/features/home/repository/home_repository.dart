import '../../../core/api/dio_client.dart';
import '../../../core/exceptions/api_error_handler.dart';
import '../../../core/exceptions/api_exception.dart';
import '../models/home_model.dart';

class HomeRepository {
  Future<HomeData> getHomeData() async {
    try {
      final response = await DioClient.instance.get('/home');
      final responseData = response.data;

      if (responseData['status'] != true) {
        throw ApiException(
          responseData['message'] ?? 'Failed to load home data',
        );
      }

      return HomeData.fromJson(responseData['data']);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
