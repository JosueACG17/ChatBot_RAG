import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class PersistenceService {
  static const String _messagesKey = 'chat_messages';
  static const String _themeKey = 'theme_mode';

  // Guardar mensajes
  static Future<void> saveMessages(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = messages.map((m) => m.toJson()).toList();
    await prefs.setString(_messagesKey, jsonEncode(messagesJson));
  }

  // Cargar mensajes
  static Future<List<Message>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesString = prefs.getString(_messagesKey);
    
    if (messagesString == null) return [];
    
    try {
      final messagesJson = jsonDecode(messagesString) as List;
      return messagesJson
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Limpiar historial
  static Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
  }

  // Guardar tema
  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  // Cargar tema
  static Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // Default: modo claro
  }
}