class DevelopmentCategory {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final int sortOrder;

  DevelopmentCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.sortOrder = 0,
  });

  factory DevelopmentCategory.fromJson(Map<String, dynamic> json) {
    return DevelopmentCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

class DevelopmentAssessment {
  final int id;
  final int childId;
  final int categoryId;
  final String? indicator;
  final String? notes;
  final String progress;
  final String? observationDate;
  final String? categoryName;
  final String? categoryIcon;

  DevelopmentAssessment({
    required this.id,
    required this.childId,
    required this.categoryId,
    this.indicator,
    this.notes,
    required this.progress,
    this.observationDate,
    this.categoryName,
    this.categoryIcon,
  });

  double get progressPercentage {
    switch (progress) {
      case 'belum':
        return 0;
      case 'mulai':
        return 25;
      case 'berkembang':
        return 50;
      case 'baik':
        return 75;
      case 'sangat_baik':
        return 100;
      default:
        return 0;
    }
  }

  String get progressLabel {
    switch (progress) {
      case 'belum':
        return 'Belum';
      case 'mulai':
        return 'Mulai';
      case 'berkembang':
        return 'Berkembang';
      case 'baik':
        return 'Baik';
      case 'sangat_baik':
        return 'Sangat Baik';
      default:
        return progress;
    }
  }

  factory DevelopmentAssessment.fromJson(Map<String, dynamic> json) {
    return DevelopmentAssessment(
      id: json['id'],
      childId: json['child_id'],
      categoryId: json['development_category_id'],
      indicator: json['indicator'],
      notes: json['notes'],
      progress: json['progress'],
      observationDate: json['observation_date'],
      categoryName: json['category']?['name'],
      categoryIcon: json['category']?['icon'],
    );
  }
}

class DevelopmentTimeline {
  final String month;
  final String monthLabel;
  final List<DevelopmentAssessment> assessments;

  DevelopmentTimeline({
    required this.month,
    required this.monthLabel,
    required this.assessments,
  });

  factory DevelopmentTimeline.fromJson(Map<String, dynamic> json) {
    return DevelopmentTimeline(
      month: json['month'],
      monthLabel: json['month_label'],
      assessments: (json['assessments'] as List)
          .map((a) => DevelopmentAssessment.fromJson(a))
          .toList(),
    );
  }
}
