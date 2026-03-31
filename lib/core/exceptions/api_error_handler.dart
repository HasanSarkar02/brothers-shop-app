import 'package:dio/dio.dart';
import 'api_exception.dart';

class ApiErrorHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      // ── Server Error with Response ──
      if (error.response != null && error.response?.data != null) {
        final data = error.response!.data;
        final statusCode = error.response!.statusCode;

        //Laravel Validation Errors (422)
        if (statusCode == 422 && data['errors'] != null) {
          final Map<String, dynamic> errors = data['errors'];
          final String firstErrorMsg = errors.values.first[0];
          return ApiException(firstErrorMsg, statusCode: statusCode);
        }

        if (data['message'] != null) {
          return ApiException(data['message'], statusCode: statusCode);
        }
      }

      // ── Connection or Timeout Errors ──
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException('Connection timed out. Please try again.');
        case DioExceptionType.connectionError:
          return ApiException('No internet connection.');
        default:
          return ApiException('Something went wrong. Please try again.');
      }
    }

    // ── Unknown Errors ──
    return ApiException(error.toString());
  }
}
