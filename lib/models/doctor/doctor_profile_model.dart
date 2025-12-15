class DoctorProfileModel {
  final String email;
  final String phone;
  final List<String> qualifications;
  final String experience;

  DoctorProfileModel({
    required this.email,
    required this.phone,
    required this.qualifications,
    required this.experience,
  });

  factory DoctorProfileModel.fromMap(Map<String, dynamic> map) {
    return DoctorProfileModel(
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      qualifications: List<String>.from(map['qualifications'] ?? []),
      experience: map['experience'] ?? '',
    );
  }
}
