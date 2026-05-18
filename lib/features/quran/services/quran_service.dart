import 'dart:convert';

import 'package:flutter/services.dart';

class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.transliteration,
    required this.revelationPlace,
    required this.versesCount,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String transliteration;
  final String revelationPlace;
  final int versesCount;
}

class QuranAyah {
  const QuranAyah({
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final int chapter;
  final int verse;
  final String text;
}

class QuranService {
  QuranService._();

  static List<QuranSurah>? _surahs;
  static Map<String, dynamic>? _quran;

  static Future<List<QuranSurah>> loadSurahs() async {
    if (_surahs != null) return _surahs!;

    final raw = await rootBundle.loadString('assets/json/metadata.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    _surahs = decoded.map((item) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as Map<String, dynamic>;
      final revelationPlace = map['revelation_place'] as Map<String, dynamic>;

      return QuranSurah(
        number: map['number'] as int,
        nameArabic: name['ar'] as String,
        nameEnglish: name['en'] as String,
        transliteration: name['transliteration'] as String,
        revelationPlace: revelationPlace['ar'] as String,
        versesCount: map['verses_count'] as int,
      );
    }).toList();

    return _surahs!;
  }

  static Future<List<QuranAyah>> loadAyahs(int surahNumber) async {
    _quran ??=
        jsonDecode(await rootBundle.loadString('assets/json/quran.json'))
            as Map<String, dynamic>;

    final rawAyahs = (_quran!['$surahNumber'] as List<dynamic>? ?? []);

    return rawAyahs.map((item) {
      final map = item as Map<String, dynamic>;
      return QuranAyah(
        chapter: map['chapter'] as int,
        verse: map['verse'] as int,
        text: map['text'] as String,
      );
    }).toList();
  }
}
