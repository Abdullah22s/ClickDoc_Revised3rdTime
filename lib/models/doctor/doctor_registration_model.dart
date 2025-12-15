class DoctorRegistrationModel {
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String experience;
  final List<String> qualifications;

  DoctorRegistrationModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.experience,
    required this.qualifications,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'experience': experience,
      'qualifications': qualifications,
      'createdAt': DateTime.now(),
    };
  }
}
