import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/persistence_service.dart';
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

  ChatController(this._repository) : super(ChatState()) {
    _loadMessages();
  }

  // Cargar mensajes guardados
  Future<void> _loadMessages() async {
    try {
      final savedMessages = await PersistenceService.loadMessages();
      state = state.copyWith(messages: savedMessages);
    } catch (e) {
      debugPrint('Error cargando mensajes: $e');
    }
  }

  // Guardar mensajes
  Future<void> _saveMessages() async {
    try {
      await PersistenceService.saveMessages(state.messages);
    } catch (e) {
      debugPrint('Error guardando mensajes: $e');
    }
  }

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
      // Crear mensaje del asistente vacío para streaming
      final assistantMessage = Message(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );

      // Agregar mensaje vacío del asistente
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
      );

      String fullAnswer = '';
      
      // Usar streaming para mostrar respuesta en tiempo real
      await for (final token in _repository.askStream(text.trim(), state.messages.sublist(0, state.messages.length - 1))) {
        fullAnswer += token;
        
        // Actualizar el último mensaje (del asistente) con el contenido acumulado
        final updatedMessages = [...state.messages];
        updatedMessages[updatedMessages.length - 1] = Message(
          role: 'assistant',
          content: fullAnswer,
          timestamp: assistantMessage.timestamp,
        );
        
        state = state.copyWith(messages: updatedMessages);
      }

      // Finalizar loading
      state = state.copyWith(isLoading: false);

      // Guardar mensajes después de cada respuesta
      await _saveMessages();
    } catch (e) {
      debugPrint('Error en chat: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> clearMessages() async {
    state = ChatState();
    await PersistenceService.clearMessages();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> checkConnection() async {
    return await _repository.health();
  }
}