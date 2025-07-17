class HealthTip {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final String? imageUrl;
  final int readingTime; // in minutes

  HealthTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.createdAt,
    this.imageUrl,
    required this.readingTime,
  });

  factory HealthTip.fromMap(Map<String, dynamic> map) {
    return HealthTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      imageUrl: map['imageUrl'],
      readingTime: map['readingTime'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'readingTime': readingTime,
    };
  }
}
