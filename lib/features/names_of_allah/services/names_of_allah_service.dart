import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tarteel/features/names_of_allah/models/name_model.dart';

class NamesOfAllahService {
  static Future<List<AllahName>> loadNames() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/names_of_allah.json',
      );
      final List<dynamic> data = jsonDecode(jsonString);
      return data.map((e) => AllahName.fromJson(e)).toList();
    } catch (e) {
      // Return empty list on failure or log the error
      return [];
    }
  }
}
