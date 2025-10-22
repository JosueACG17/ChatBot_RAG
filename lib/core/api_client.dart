import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    final baseUrl = _getBaseUrl();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
  }

  String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Para emulador Android
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // Para simulador iOS
      return 'http://localhost:8000';
    } else {
      // Para dispositivos físicos - cambiar por la IP real
      return 'http://192.168.1.100:8000';
    }
  }

  Future<ChatResponse> sendMessage(ChatRequest request) async {
    try {
      final response = await _dio.post('/chat', data: request.toJson());
      return ChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica que el servidor esté funcionando';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return 'Error del servidor ($statusCode)';
      default:
        return 'Error de conexión: ${error.message}';
    }
  }
}