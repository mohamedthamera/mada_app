import 'package:dio/dio.dart';

class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  late final Dio _dio;

  Dio get client => _dio;
}

