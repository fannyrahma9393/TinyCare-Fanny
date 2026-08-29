class Child {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? photoUrl;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? packageName;
  final String? status;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.photoUrl,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.packageName,
    this.status,
  });

  String get fullName => '$firstName $lastName';

  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get ageText => '$age tahun';

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      photoUrl: json['photo_url'],
      parentName: json['parent'] != null
          ? '${json['parent']['first_name']} ${json['parent']['last_name']}'
          : null,
      parentPhone: json['parent']?['phone'],
      parentEmail: json['parent']?['email'],
      packageName: json['package']?['name'],
      status: json['status'],
    );
  }
}
