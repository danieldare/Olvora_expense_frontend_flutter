import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting conversation state locally
class ConversationStorageService {
  static const String _lastConversationIdKey = 'ora_last_conversation_id';

  /// Get the last conversation ID from local storage
  Future<String?> getLastConversationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastConversationIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Save the conversation ID to local storage
  Future<void> saveLastConversationId(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConversationIdKey, conversationId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Clear the stored conversation ID
  Future<void> clearLastConversationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastConversationIdKey);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}
