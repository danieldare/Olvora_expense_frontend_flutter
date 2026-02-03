import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves user's category mappings for future imports
class MappingMemory {
  static const String _prefix = 'import_mapping_';

  Future<String?> getMapping(String originalName) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = originalName.toLowerCase().trim();
    return prefs.getString('$_prefix$normalized');
  }

  Future<void> saveMapping(String originalName, String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = originalName.toLowerCase().trim();
    await prefs.setString('$_prefix$normalized', categoryName);
  }

  Future<void> deleteMapping(String originalName) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = originalName.toLowerCase().trim();
    await prefs.remove('$_prefix$normalized');
  }

  Future<Map<String, String>> getAllMappings() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    final mappings = <String, String>{};
    
    for (final key in keys) {
      final originalName = key.substring(_prefix.length);
      final categoryName = prefs.getString(key);
      if (categoryName != null) {
        mappings[originalName] = categoryName;
      }
    }
    
    return mappings;
  }
}
