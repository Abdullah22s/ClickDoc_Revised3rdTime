class PhysicalOpdModel {
  final String id;
  final String hospitalName;
  final String day; // We will treat this as a string for the UI
  final String department;
  final String city;
  final String fromTime;
  final String toTime;
  final List<Map<String, String>> slots;

  PhysicalOpdModel({
    required this.id,
    required this.hospitalName,
    required this.day,
    required this.department,
    required this.city,
    required this.fromTime,
    required this.toTime,
    required this.slots,
  });

  factory PhysicalOpdModel.fromMap(String id, Map<String, dynamic> map) {
    // Handling 'days' which is saved as a List in your setup
    String dayString = 'Unknown';
    if (map['days'] is List && (map['days'] as List).isNotEmpty) {
      dayString = (map['days'] as List).join(', ');
    }

    return PhysicalOpdModel(
      id: id,
      hospitalName: map['hospitalName'] ?? 'Unknown',
      day: dayString,
      department: map['department'] ?? 'Unknown',
      city: map['city'] ?? 'Unknown',
      // 🔥 KEYS FIXED: Matching 'startTime' and 'endTime' from your Setup ViewModel
      fromTime: map['startTime'] ?? '--:--',
      toTime: map['endTime'] ?? '--:--',
      slots: List<Map<String, String>>.from(
        (map['slots'] as List? ?? []).map((s) => Map<String, String>.from(s)),
      ),
    );
  }
}

class DoctorPhysicalOpdModel {
  final String id;
  final String name;
  final List<String> qualifications;
  final List<PhysicalOpdModel> opds;

  DoctorPhysicalOpdModel({
    required this.id,
    required this.name,
    required this.qualifications,
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