class ZekrModel {

  final String category;

  final String count;

  final String description;

  final String reference;

  final String content;

  int currentCount;

  ZekrModel({
    required this.category,
    required this.count,
    required this.description,
    required this.reference,
    required this.content,
    this.currentCount = 0,
  });

  factory ZekrModel.fromJson(Map<String, dynamic> json) {

    return ZekrModel(
      category: json['category'] ?? '',
      count: json['count'] ?? '1',
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
      content: json['content'] ?? '',
    );
  }
}