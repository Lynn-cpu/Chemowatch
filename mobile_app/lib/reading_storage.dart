import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'vital_reading.dart';

// Saves and loads readings on this device.
class ReadingStorage {
  static const String _storageKey = 'chemowatch_readings';

  static Future<void> saveReadings(List<VitalReading> readings) async {
    final prefs = await SharedPreferences.getInstance();
    final readingMaps = readings.map((reading) => reading.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(readingMaps));
  }

  static Future<List<VitalReading>> loadReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonText = prefs.getString(_storageKey);
    if (jsonText == null || jsonText.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      return decoded.map((item) {
        return VitalReading.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}