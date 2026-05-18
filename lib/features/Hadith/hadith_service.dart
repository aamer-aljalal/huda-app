import 'dart:convert';

import 'package:flutter/services.dart';

class HadithModel {
  const HadithModel({
    required this.number,
    required this.hadith,
    required this.description,
    required this.searchTerm,
  });

  final int number;
  final String hadith;
  final String description;
  final String searchTerm;

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      number: json['number'] as int? ?? 0,
      hadith: _cleanText(json['hadith'] as String? ?? ''),
      description: _cleanText(json['description'] as String? ?? ''),
      searchTerm: _cleanText(json['searchTerm'] as String? ?? ''),
    );
  }

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return number.toString().contains(normalizedQuery) ||
        hadith.toLowerCase().contains(normalizedQuery) ||
        description.toLowerCase().contains(normalizedQuery) ||
        searchTerm.toLowerCase().contains(normalizedQuery);
  }

  static String _cleanText(String value) {
    return value
        .replaceAll('\u200f', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class HadithService {
  HadithService._();

  static List<HadithModel>? _cachedHadiths;

  static Future<List<HadithModel>> loadHadiths() async {
    if (_cachedHadiths != null) return _cachedHadiths!;

    final raw = await rootBundle.loadString('assets/json/hadith.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    _cachedHadiths = decoded
        .map((item) => HadithModel.fromJson(item as Map<String, dynamic>))
        .where((hadith) => hadith.hadith.isNotEmpty)
        .toList();

    return _cachedHadiths!;
  }
}
