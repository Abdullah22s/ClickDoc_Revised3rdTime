class PatientFormModel {
  final String referenceNumber;
  final String name;
  final String email;
  final String age;
  final String weight;
  final String gender;
  final String bloodGroup;
  final List<String> medicalHistory;

  PatientFormModel({
    required this.referenceNumber,
    required this.name,
    required this.email,
    required this.age,
    required this.weight,
    required this.gender,
    required this.bloodGroup,
    required this.medicalHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'referenceNumber': referenceNumber,
      'name': name,
      'email': email,
      'age': age,
      'weight': weight,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'medicalHistory': medicalHistory,
      'createdAt': DateTime.now(),
    };
  }
}
