import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';

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

  /// Fetch online clinics for a doctor document
  Future<DoctorOnlineClinicModel> doctorFromSnapshot(QueryDocumentSnapshot doctorDoc) async {
    final doctorId = doctorDoc.id;
    final doctorData = doctorDoc.data() as Map<String, dynamic>;

    final clinicSnapshot = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .orderBy('createdAt', descending: true)
        .get();

    if (clinicSnapshot.docs.isEmpty) {
      throw Exception("No clinics found for doctor $doctorId");
    }

    final firstClinicData = clinicSnapshot.docs.first.data() as Map<String, dynamic>;

    List<AppointmentSlot> slots = [];
    if (firstClinicData['slots'] != null) {
      slots = (firstClinicData['slots'] as List)
          .map((s) => AppointmentSlot(start: s['start'], end: s['end']))
          .toList();
    }

    return DoctorOnlineClinicModel(
      id: clinicSnapshot.docs.first.id,
      doctorId: doctorId,
      doctorName: doctorData['name'] ?? 'Not specified',
      doctorQualification: doctorData['qualification'] ?? '',
      department: firstClinicData['department'] ?? 'Not specified',
      startTime: firstClinicData['startTime'] ?? '',
      endTime: firstClinicData['endTime'] ?? '',
      fees: firstClinicData['fees'] ?? 0,
      appointmentDuration: firstClinicData['appointmentDuration'] ?? 15,
      bufferDuration: firstClinicData['bufferDuration'] ?? 0,
      days: List<String>.from(firstClinicData['days'] ?? []),
      slots: slots,
    );
  }

  /// Stream of all doctors
  Stream<QuerySnapshot> get doctorsStream => _firestore.collection('doctors').snapshots();

  /// Search filter
  bool matchesSearch(DoctorOnlineClinicModel doctor) {
    final query = searchQuery.toLowerCase();
    if (doctor.doctorName.toLowerCase().contains(query)) return true;
    if (doctor.department.toLowerCase().contains(query)) return true;
    return false;
  }
}
