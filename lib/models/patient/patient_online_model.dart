class ClinicModel {
  final String department;
  final String startTime;
  final String endTime;
  final int fees;
  final List<String> days;
  final List<Map<String, String>> slots;

  ClinicModel({
    required this.department,
    required this.startTime,
    required this.endTime,
    required this.fees,
    required this.days,
    required this.slots,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map) {
    return ClinicModel(
      department: map['department'] ?? 'Not specified',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      fees: map['fees'] ?? 0,
      days: List<String>.from(map['days'] ?? []),
      slots: List<Map<String, String>>.from(map['slots'] ?? []),
    );
  }

  factory ClinicModel.fromJson(Map<String, dynamic> json) => ClinicModel.fromMap(json);
}

class PatientOnlineModel {
  final String id;
  final String name;
  final List<ClinicModel> clinics;

  PatientOnlineModel({
    required this.id,
    required this.name,
    required this.clinics,
  });

  factory PatientOnlineModel.fromMap(String id, Map<String, dynamic> map, List<ClinicModel> clinics) {
    return PatientOnlineModel(
      id: id,
      name: map['name'] ?? 'Unknown',
      clinics: clinics,
    );
  }

  factory PatientOnlineModel.fromJson(Map<String, dynamic> json) {
    return PatientOnlineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      clinics: (json['clinics'] as List<dynamic>? ?? [])
          .map((c) => ClinicModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
