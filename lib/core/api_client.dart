import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    final baseUrl = _getBaseUrl();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
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
    final envBaseUrl = dotenv.env['BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    throw Exception('BASE_URL no está configurada en el archivo .env');
  }

  Future<ChatResponse> sendMessage(ChatRequest request) async {
    try {
      final response = await _dio.post('/chat', data: request.toJson());
      return ChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Streaming para tokens (simulado)
  Stream<String> sendMessageStream(ChatRequest request) async* {
    try {
      final response = await _dio.post('/chat', data: request.toJson());
      final chatResponse = ChatResponse.fromJson(response.data);
      final fullAnswer = chatResponse.answer;
      
      // Simular streaming dividiendo la respuesta en palabras
      final words = fullAnswer.split(' ');
      for (int i = 0; i < words.length; i++) {
        await Future.delayed(const Duration(milliseconds: 50)); 
        if (i == 0) {
          yield words[i];
        } else {
          yield ' ${words[i]}';
        }
      }
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
        return 'Ha ocurrido un error en el servidor';
      case DioExceptionType.sendTimeout:
        return 'Ha ocurrido un error en el servidor';
      case DioExceptionType.receiveTimeout:
        return 'Ha ocurrido un error en el servidor';
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