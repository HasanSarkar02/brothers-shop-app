import '../../../core/api/dio_client.dart';
import '../models/home_model.dart';

class HomeRepository {
  Future<HomeData> getHomeData() async {
    final response = await DioClient.instance.get('/home');
    return HomeData.fromJson(response.data['data']);
  }
}
