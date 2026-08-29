class Attendance {
  final int id;
  final int childId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final String? notes;
  final String? childName;

  Attendance({
    required this.id,
    required this.childId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.notes,
    this.childName,
  });

  String get statusLabel {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'tidak_hadir':
        return 'Tidak Hadir';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'hadir':
        return 'green';
      case 'tidak_hadir':
        return 'red';
      case 'izin':
        return 'yellow';
      case 'sakit':
        return 'orange';
      default:
        return 'gray';
    }
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      childId: json['child_id'],
      date: json['date'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      status: json['status'],
      notes: json['notes'],
      childName: json['child'] != null
          ? '${json['child']['first_name']} ${json['child']['last_name']}'
          : null,
    );
  }
}
