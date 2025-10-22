import '../../core/api_client.dart';
import '../../core/models.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  Future<String> ask(String message, List<Message> history) async {
    // Convertir el historial al formato de la API
    final historyForApi = history.map((msg) => {
      'role': msg.role,
      'content': msg.content,
    }).toList();

    final request = ChatRequest(
      message: message,
      history: historyForApi,
    );

    final response = await _apiClient.sendMessage(request);
    return response.answer;
  }

  Future<bool> health() async {
    return await _apiClient.checkHealth();
  }
}