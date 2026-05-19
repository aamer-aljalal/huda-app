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

  factory HadithModel.fromJson(Map<String, dynamic> json, int number) {
    final rawHadith = json['hadith'] as String? ?? '';
    final rawDesc = json['description'] as String? ?? '';
    return HadithModel(
      number: number,
      hadith: _cleanText(rawHadith),
      description: _cleanText(rawDesc),
      searchTerm: _cleanText(rawHadith),
    );
  }

  List<String> _parseHadith() {
    final clean = hadith.trim();
    if (!clean.startsWith('الحديث')) {
      return ['الحديث $number', clean];
    }

    // 1. Try splitting by real newline
    if (clean.contains('\n')) {
      final lines = clean.split('\n');
      final firstLine = lines.first.trim();
      if (firstLine.startsWith('الحديث')) {
        final rest = lines.sublist(1).join('\n').trim();
        return [firstLine, rest];
      }
    }

    // 2. Fallback: Split by the narrator keyword 'عن' or 'عـن' (using lookahead regex)
    final match = RegExp(r'^(الحديث\s+[^\n\r]+?)(?=\s+عـ?ن\s+)').firstMatch(clean);
    if (match != null) {
      final title = match.group(1)!.trim();
      final rest = clean.substring(match.end).trim();
      return [title, rest];
    }

    // 3. Alternative fallback: Parse ordinal words starting the sentence
    final words = clean.split(RegExp(r'\s+'));
    if (words.length >= 3 && words[0] == 'الحديث') {
      if (words[1] == 'الحادي' || words[1] == 'الثاني' || words[1] == 'الثالث' || words[1] == 'الرابع' || words[1] == 'الخامس') {
        if (words[2] == 'والعشرون' || words[2] == 'والثلاثون' || words[2] == 'والأربعون') {
          final title = '${words[0]} ${words[1]} ${words[2]}';
          final rest = clean.substring(title.length).trim();
          return [title, rest];
        }
      }
      if (words[2] == 'عشر') {
        final title = '${words[0]} ${words[1]} ${words[2]}';
        final rest = clean.substring(title.length).trim();
        return [title, rest];
      }
      final title = '${words[0]} ${words[1]}';
      final rest = clean.substring(title.length).trim();
      return [title, rest];
    }

    return ['الحديث $number', clean];
  }

  String get shortTitle => _parseHadith()[0];

  String get textOnly => _parseHadith()[1];

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
        .split('\n')
        .map((line) => line
            .replaceAll('\u200f', ' ')
            .replaceAll(RegExp(r'[ \t\u200b\u200c\u200d]+'), ' ')
            .trim())
        .join('\n');
  }
}

class HadithService {
  HadithService._();

  static List<HadithModel>? _cachedHadiths;

  static Future<List<HadithModel>> loadHadiths() async {
    if (_cachedHadiths != null) return _cachedHadiths!;

    final raw = await rootBundle.loadString('assets/json/hadith_nawawi.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    _cachedHadiths = decoded.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      return HadithModel.fromJson(item, index + 1);
    }).where((hadith) => hadith.hadith.isNotEmpty).toList();

    return _cachedHadiths!;
  }
}
