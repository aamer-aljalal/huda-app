import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prophet_story_model.dart';

class ProphetsStoriesService {
  ProphetsStoriesService._();

  static const String _favoritesKey = 'favorite_prophet_stories_ids';
  static List<ProphetStoryModel>? _cachedStories;

  /// Loads all stories of the prophets from the JSON asset
  static Future<List<ProphetStoryModel>> loadStories() async {
    if (_cachedStories != null) return _cachedStories!;

    try {
      final raw = await rootBundle.loadString('assets/json/Stories/Stories_Prophets.json');
      final decoded = jsonDecode(raw) as List<dynamic>;

      _cachedStories = decoded.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        return ProphetStoryModel.fromJson(item, index + 1);
      }).where((story) => story.name.isNotEmpty && story.story.isNotEmpty).toList();

      return _cachedStories!;
    } catch (e) {
      // Return empty list if loading fails
      return [];
    }
  }

  /// Get bookmarked/favorite prophet story IDs from SharedPreferences
  static Future<Set<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? [];
    return list.map((idStr) => int.tryParse(idStr)).whereType<int>().toSet();
  }

  /// Toggle favorite status of a story
  static Future<bool> toggleFavorite(int storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    bool added;
    if (favorites.contains(storyId)) {
      favorites.remove(storyId);
      added = false;
    } else {
      favorites.add(storyId);
      added = true;
    }

    await prefs.setStringList(
      _favoritesKey,
      favorites.map((id) => id.toString()).toList(),
    );
    return added;
  }
}
