/// Defensive Event model that handles all edge cases from the backend API.
/// Backend parentIndex returns Eloquent models serialized to JSON.
/// The `date` field is cast to 'date' in the model, so it becomes an
/// ISO 8601 string like "2026-08-26T00:00:00.000000Z".
class Event {
  final int id;
  final String title;
  final String? description;
  final String type;
  final String date; // Can be ISO 8601 or simple date string
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String status;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.date,
    this.endDate,
    this.startTime,
    this.endTime,
    this.status = 'scheduled',
  });

  String get eventType => type;
  String get startDate => date;

  /// Get display date as simple "YYYY-MM-DD" regardless of input format
  String get displayDate {
    if (date.isEmpty) return '';
    // Handle ISO 8601: "2026-08-26T00:00:00.000000Z"
    if (date.contains('T')) {
      return date.split('T').first;
    }
    return date;
  }

  String get typeLabel {
    switch (type) {
      case 'activity':
        return 'Aktivitas';
      case 'holiday':
        return 'Libur';
      case 'special':
        return 'Acara Khusus';
      case 'meeting':
        return 'Meeting';
      default:
        return type;
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'activity':
        return '🎯';
      case 'holiday':
        return '🏖️';
      case 'special':
        return '🎉';
      case 'meeting':
        return '🤝';
      default:
        return '📅';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return 'Terjadwal';
      case 'ongoing':
        return 'Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Parse date to get day number (e.g., "26" from "2026-08-26")
  String get dayOfMonth {
    final d = displayDate;
    if (d.isEmpty) return '?';
    final parts = d.split('-');
    if (parts.length >= 3) return parts[2];
    return '?';
  }

  /// Parse date to get month number (e.g., "8" from "2026-08-26")
  int get monthNumber {
    final d = displayDate;
    if (d.isEmpty) return 0;
    final parts = d.split('-');
    if (parts.length >= 2) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    // Defensive parsing - handle all possible field names and null values
    final rawId = json['id'];
    final int eventId = rawId is int ? rawId : (rawId is String ? (int.tryParse(rawId) ?? 0) : 0);

    final rawType = json['type'] ?? json['event_type'];
    final String eventType = rawType is String ? rawType : 'activity';

    final rawDate = json['date'] ?? json['start_date'] ?? '';
    final String eventDate = rawDate is String ? rawDate : rawDate.toString();

    final rawEndDate = json['end_date'];
    final String? endDate = rawEndDate is String ? rawEndDate : null;

    final rawStartTime = json['start_time'];
    final String? startTime = rawStartTime is String ? rawStartTime : null;

    final rawEndTime = json['end_time'];
    final String? endTime = rawEndTime is String ? rawEndTime : null;

    final rawStatus = json['status'];
    final String status = rawStatus is String ? rawStatus : 'scheduled';

    final rawTitle = json['title'];
    final String title = rawTitle is String ? rawTitle : '';

    final rawDescription = json['description'];
    final String? description = rawDescription is String ? rawDescription : null;

    return Event(
      id: eventId,
      title: title,
      description: description,
      type: eventType,
      date: eventDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      status: status,
    );
  }
}
