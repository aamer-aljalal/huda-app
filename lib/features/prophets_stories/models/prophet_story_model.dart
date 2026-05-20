class ProphetStoryModel {
  final int id;
  final String name;
  final String story;
  final String excerpt;

  const ProphetStoryModel({
    required this.id,
    required this.name,
    required this.story,
    required this.excerpt,
  });

  factory ProphetStoryModel.fromJson(Map<String, dynamic> json, int id) {
    final name = json['prophet'] as String? ?? '';
    final story = json['story'] as String? ?? '';
    
    // Create excerpt from the first paragraph or first 150 characters of the story
    String cleanStory = story.trim();
    // remove newlines at the beginning
    while (cleanStory.startsWith('\n')) {
      cleanStory = cleanStory.substring(1).trim();
    }
    
    // Remove "نبذة:" or other markers for excerpt if present
    String excerptBase = cleanStory.replaceAll('            نبذة:\n\n', '').replaceAll('نبذة:\n', '');
    String excerpt = excerptBase.length > 150 
        ? '${excerptBase.substring(0, 147).replaceAll('\n', ' ')}...'
        : excerptBase.replaceAll('\n', ' ');

    return ProphetStoryModel(
      id: id,
      name: name.trim(),
      story: story,
      excerpt: excerpt.trim(),
    );
  }

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    return name.toLowerCase().contains(normalizedQuery) ||
        story.toLowerCase().contains(normalizedQuery);
  }
}
