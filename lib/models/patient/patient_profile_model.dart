class PatientProfileModel {
  final String referenceNumber;
  final String email;
  final String age;
  final String weight;
  final String gender;
  final String bloodGroup;
  final List<String> medicalHistory;

  PatientProfileModel({
    required this.referenceNumber,
    required this.email,
    required this.age,
    required this.weight,
    required this.gender,
    required this.bloodGroup,
    required this.medicalHistory,
  });

  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    return PatientProfileModel(
      referenceNumber: map['referenceNumber'] ?? '',
      email: map['email'] ?? '',
      age: map['age']?.toString() ?? 'N/A',
      weight: map['weight']?.toString() ?? 'N/A',
      gender: map['gender'] ?? 'N/A',
      bloodGroup: map['bloodGroup'] ?? 'N/A',
      medicalHistory: map['medicalHistory'] != null
          ? List<String>.from(map['medicalHistory'])
          : [],
    );
  }
}
