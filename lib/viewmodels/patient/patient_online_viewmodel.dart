import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/patient/patient_online_model.dart';

class PatientOnlineViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> expandedDoctor = {};
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();

  /// Update search query
  void updateSearch(String value) {
    searchQuery = value.trim();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    searchQuery = '';
    searchController.clear();
    notifyListeners();
  }

  /// Toggle doctor expansion
  void toggleDoctorExpansion(String doctorId) {
    expandedDoctor[doctorId] = !(expandedDoctor[doctorId] ?? false);
    notifyListeners();
  }

  /// Convert Firestore snapshot to PatientOnlineModel
  Future<PatientOnlineModel> doctorFromSnapshot(QueryDocumentSnapshot doctorDoc) async {
    final doctorId = doctorDoc.id;
    final doctorData = doctorDoc.data() as Map<String, dynamic>;

    final clinicSnapshot = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .get();

    final clinics = clinicSnapshot.docs
        .map((c) => ClinicModel.fromMap(c.data() as Map<String, dynamic>))
        .toList();

    return PatientOnlineModel.fromMap(doctorId, doctorData, clinics);
  }

  /// Stream of doctors
  Stream<QuerySnapshot> get doctorsStream => _firestore.collection('doctors').snapshots();

  /// Filter logic
  bool matchesSearch(PatientOnlineModel doctor) {
    final query = searchQuery.toLowerCase();
    if (doctor.name.toLowerCase().contains(query)) return true;
    for (var clinic in doctor.clinics) {
      if (clinic.department.toLowerCase().contains(query)) return true;
    }
    return false;
  }
}
