class Announcement {
  final int id;
  final String title;
  final String? content;
  final String priority;
  final String? publishDate;
  final String? expireDate;
  final bool isPublished;

  Announcement({
    required this.id,
    required this.title,
    this.content,
    required this.priority,
    this.publishDate,
    this.expireDate,
    this.isPublished = true,
  });

  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return 'Mendesak';
      case 'high':
        return 'Penting';
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Rendah';
      default:
        return priority;
    }
  }

  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return 'red';
      case 'high':
        return 'orange';
      case 'normal':
        return 'blue';
      case 'low':
        return 'gray';
      default:
        return 'gray';
    }
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      priority: json['priority'] ?? 'normal',
      publishDate: json['publish_date'],
      expireDate: json['expire_date'],
      isPublished: json['is_published'] ?? true,
    );
  }
}
