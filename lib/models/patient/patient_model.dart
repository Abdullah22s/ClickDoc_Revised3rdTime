class PatientModel {
  final String id;
  final String name;
  final String email;
  final String gender;
  final String referenceNumber;
  final String age;
  final String weight;
  final String bloodGroup;
  final List<String> medicalHistory;

  PatientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.referenceNumber,
    required this.age,
    required this.weight,
    required this.bloodGroup,
    required this.medicalHistory,
  });

  factory PatientModel.fromMap(String id, Map<String, dynamic> data) {
    return PatientModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      referenceNumber: data['referenceNumber'] ?? '',
      age: data['age']?.toString() ?? '',
      weight: data['weight']?.toString() ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      medicalHistory: List<String>.from(data['medicalHistory'] ?? []),
    );
  }
}
