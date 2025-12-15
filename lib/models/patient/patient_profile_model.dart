class PatientProfileModel {
  final String email;
  final int? age;
  final double? weight;
  final String? gender;
  final String? medicalHistory;

  PatientProfileModel({
    required this.email,
    this.age,
    this.weight,
    this.gender,
    this.medicalHistory,
  });

  /// Create model from Firestore map
  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    return PatientProfileModel(
      email: map['email'] ?? '',
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      gender: map['gender'],
      medicalHistory: map['medicalHistory'],
    );
  }

  /// Convert model back to map (useful for updates)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'age': age,
      'weight': weight,
      'gender': gender,
      'medicalHistory': medicalHistory,
    };
  }
}
