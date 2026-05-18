class AllahName {
  final int id;
  final String name;
  final String text;

  const AllahName({
    required this.id,
    required this.name,
    required this.text,
  });

  factory AllahName.fromJson(Map<String, dynamic> json) {
    return AllahName(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'text': text,
    };
  }
}
