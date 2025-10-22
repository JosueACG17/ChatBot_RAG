// Modelos para el chatbot RAG
class Message {
  final String role; // 'user' o 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatRequest {
  final String message;
  final List<Map<String, String>> history;

  ChatRequest({
    required this.message,
    required this.history,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'history': history,
      };
}

class ChatResponse {
  final String answer;

  ChatResponse({required this.answer});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(answer: json['answer'] ?? '');
  }
}

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}