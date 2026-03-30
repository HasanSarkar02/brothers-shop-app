import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Token add করো
          final token = await LocalStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Guest session
          final guestSession = await LocalStorage.getGuestSessionId();
          options.headers['X-Guest-Session'] = guestSession;

          return handler.next(options);
        },

        onError: (error, handler) async {
          // 401 — token invalid, logout করো
          if (error.response?.statusCode == 401) {
            await LocalStorage.deleteToken();
            await LocalStorage.clearUser();
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
