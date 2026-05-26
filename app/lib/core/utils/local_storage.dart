import 'package:mini_obieraki/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  Future<List<String>> getSavedOpiniaIdentifiers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.savedOpiniaIdsKey) ?? [];
  }

  Future<void> addOpiniaIdentifier(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getStringList(AppConstants.savedOpiniaIdsKey) ?? [];
    if (!existing.contains(identifier)) {
      existing.add(identifier);
      await prefs.setStringList(AppConstants.savedOpiniaIdsKey, existing);
    }
  }
}
