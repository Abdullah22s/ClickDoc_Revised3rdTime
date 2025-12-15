class PatientFormModel {
  final String name;
  final String email;
  final String age;
  final String weight;
  final String gender;
  final List<String> medicalHistory;

  PatientFormModel({
    required this.name,
    required this.email,
    required this.age,
    required this.weight,
    required this.gender,
    required this.medicalHistory,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'weight': weight,
      'gender': gender,
      'medicalHistory': medicalHistory,
    };
  }
}
