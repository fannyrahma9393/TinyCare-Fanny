import '../utils/currency.dart';

class DailyStory {
  final int id;
  final int childId;
  final String date;
  final String? summary;
  final String? mood;
  final String? mealNotes;
  final String? sleepNotes;
  final String? adminNotes;
  final double? mealRating;
  final double? sleepHours;
  final String? childName;

  DailyStory({
    required this.id,
    required this.childId,
    required this.date,
    this.summary,
    this.mood,
    this.mealNotes,
    this.sleepNotes,
    this.adminNotes,
    this.mealRating,
    this.sleepHours,
    this.childName,
  });

  String get moodEmoji {
    switch (mood) {
      case 'bahagia':
        return '😊';
      case 'biasa':
        return '😐';
      case 'sedih':
        return '😢';
      case 'sakit':
        return '🤒';
      case 'rewel':
        return '😫';
      default:
        return '😐';
    }
  }

  String get moodLabel {
    switch (mood) {
      case 'bahagia':
        return 'Bahagia';
      case 'biasa':
        return 'Biasa';
      case 'sedih':
        return 'Sedih';
      case 'sakit':
        return 'Sakit';
      case 'rewel':
        return 'Rewel';
      default:
        return 'Tidak Diketahui';
    }
  }

  factory DailyStory.fromJson(Map<String, dynamic> json) {
    return DailyStory(
      id: json['id'],
      childId: json['child_id'],
      date: json['date'] ?? '',
      summary: json['summary'],
      mood: json['mood'],
      mealNotes: json['meal_notes'],
      sleepNotes: json['sleep_notes'],
      adminNotes: json['admin_notes'],
      mealRating: json['meal_rating'] != null
          ? CurrencyHelper.parseToDouble(json['meal_rating'])
          : null,
      sleepHours: json['sleep_hours'] != null
          ? CurrencyHelper.parseToDouble(json['sleep_hours'])
          : null,
      childName: json['child'] != null
          ? '${json['child']['first_name'] ?? ''} ${json['child']['last_name'] ?? ''}'.trim()
          : null,
    );
  }
}
