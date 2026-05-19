class HisnCategory {
  final String title;
  final List<String> texts;
  final List<String> footnotes;

  HisnCategory({
    required this.title,
    required this.texts,
    required this.footnotes,
  });

  factory HisnCategory.fromJson(String title, Map<String, dynamic> json) {
    return HisnCategory(
      title: title,
      texts: List<String>.from(json['text'] ?? []),
      footnotes: List<String>.from(json['footnote'] ?? []),
    );
  }
}
