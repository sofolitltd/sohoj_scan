import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// F12: the last 10 numbers, newest first, pruned after 24 hours.
class HistoryEntry {
  const HistoryEntry({required this.number, required this.scannedAt});

  final String number;
  final DateTime scannedAt;

  Map<String, Object?> toJson() => {
        'number': number,
        'scannedAt': scannedAt.toIso8601String(),
      };

  static HistoryEntry fromJson(Map<String, Object?> json) => HistoryEntry(
        number: json['number'] as String,
        scannedAt: DateTime.parse(json['scannedAt'] as String),
      );
}

class HistoryStore {
  static const _key = 'history_v1';
  static const maxEntries = 10;
  static const expiry = Duration(hours: 24);

  Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final now = DateTime.now();
    final decoded = jsonDecode(raw) as List;
    final all = decoded
        .cast<Map<String, Object?>>()
        .map(HistoryEntry.fromJson)
        .where((e) => now.difference(e.scannedAt) < expiry)
        .toList();
    if (all.length != decoded.length) await _save(all);
    return all;
  }

  Future<void> add(String number) async {
    final entries = await load();
    entries.removeWhere((e) => e.number == number);
    entries.insert(0, HistoryEntry(number: number, scannedAt: DateTime.now()));
    await _save(entries.take(maxEntries).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
