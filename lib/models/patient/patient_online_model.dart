import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicModel {
  final String department;
  final String startTime;
  final String endTime;
  final int fees;
  final List<String> days;
  final List<Map<String, String>> slots;
  final DateTime startDateTime;
  final DateTime endDateTime;

  ClinicModel({
    required this.department,
    required this.startTime,
    required this.endTime,
    required this.fees,
    required this.days,
    required this.slots,
    required this.startDateTime,
    required this.endDateTime,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map) {
    return ClinicModel(
      department: map['department'] ?? 'Not specified',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      fees: map['fees'] ?? 0,
      days: List<String>.from(map['days'] ?? []),
      slots: List<Map<String, String>>.from(map['slots'] ?? []),
      startDateTime: map['startDateTime'] is Timestamp
          ? (map['startDateTime'] as Timestamp).toDate()
          : DateTime.tryParse(map['startDateTime'] ?? '') ?? DateTime.now(),
      endDateTime: map['endDateTime'] is Timestamp
          ? (map['endDateTime'] as Timestamp).toDate()
          : DateTime.tryParse(map['endDateTime'] ?? '') ?? DateTime.now(),
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
