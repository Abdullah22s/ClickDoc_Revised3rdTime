class PhysicalOpdModel {
  final String hospitalName;
  final String day;
  final String department;
  final String city;
  final String fromTime;
  final String toTime;

  PhysicalOpdModel({
    required this.hospitalName,
    required this.day,
    required this.department,
    required this.city,
    required this.fromTime,
    required this.toTime,
  });

  factory PhysicalOpdModel.fromMap(Map<String, dynamic> map) {
    return PhysicalOpdModel(
      hospitalName: map['hospitalName'] ?? 'Unknown',
      day: map['day'] ?? 'Unknown',
      department: map['department'] ?? 'Unknown',
      city: map['city'] ?? 'Unknown',
      fromTime: map['fromTime'] ?? '--:--',
      toTime: map['toTime'] ?? '--:--',
    );
  }
}

class DoctorPhysicalOpdModel {
  final String id;
  final String name;
  final List<String> qualifications; // new
  final List<PhysicalOpdModel> opds;

  DoctorPhysicalOpdModel({
    required this.id,
    required this.name,
    required this.qualifications, // new
    required this.opds,
  });

  factory DoctorPhysicalOpdModel.fromMap(
      String id, String name, List<String> qualifications, List<PhysicalOpdModel> opds) {
    return DoctorPhysicalOpdModel(
      id: id,
      name: name,
      qualifications: qualifications,
      opds: opds,
    );
  }
}
