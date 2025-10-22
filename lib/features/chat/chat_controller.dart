import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import 'chat_repository.dart';

// Provider para el cliente API
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Provider para el repositorio de chat
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ChatRepository(apiClient);
});

// Provider para el controlador del chat
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final repository = ref.read(chatRepositoryProvider);
  return ChatController(repository);
});

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatController(this._repository) : super(ChatState());

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Agregar mensaje del usuario y activar loading
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final answer = await _repository.ask(text.trim(), state.messages);

      final assistantMessage = Message(
        role: 'assistant',
        content: answer,
        timestamp: DateTime.now(),
      );

      // Agregar respuesta del asistente
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error en chat: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearMessages() {
    state = ChatState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> checkConnection() async {
    return await _repository.health();
  }
}