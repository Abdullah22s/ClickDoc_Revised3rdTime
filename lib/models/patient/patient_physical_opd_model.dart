class PhysicalOpdModel {
  final String hospitalName;
  final String day;
  final String department;
  final String fromTime;
  final String toTime;

  PhysicalOpdModel({
    required this.hospitalName,
    required this.day,
    required this.department,
    required this.fromTime,
    required this.toTime,
  });

  factory PhysicalOpdModel.fromMap(Map<String, dynamic> map) {
    return PhysicalOpdModel(
      hospitalName: map['hospitalName'] ?? 'Unknown',
      day: map['day'] ?? 'Unknown',
      department: map['department'] ?? 'Unknown',
      fromTime: map['fromTime'] ?? '--:--',
      toTime: map['toTime'] ?? '--:--',
    );
  }

  factory PhysicalOpdModel.fromJson(Map<String, dynamic> json) => PhysicalOpdModel.fromMap(json);
}

class DoctorPhysicalOpdModel {
  final String id;
  final String name;
  final List<PhysicalOpdModel> opds;

  DoctorPhysicalOpdModel({
    required this.id,
    required this.name,
    required this.opds,
  });

  factory DoctorPhysicalOpdModel.fromMap(String id, String name, List<PhysicalOpdModel> opds) {
    return DoctorPhysicalOpdModel(id: id, name: name, opds: opds);
  }

  factory DoctorPhysicalOpdModel.fromJson(Map<String, dynamic> json) {
    return DoctorPhysicalOpdModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      opds: (json['opds'] as List<dynamic>? ?? [])
          .map((o) => PhysicalOpdModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}
