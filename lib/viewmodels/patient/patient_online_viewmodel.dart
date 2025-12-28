import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';

class PatientOnlineViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> expandedDoctor = {};
  String nameFilter = '';
  String departmentFilter = '';

  /// Toggle doctor expansion
  void toggleDoctorExpansion(String doctorId) {
    expandedDoctor[doctorId] = !(expandedDoctor[doctorId] ?? false);
    notifyListeners();
  }

  /// Set filters from filter sheet
  void setFilters({String? name, String? department}) {
    nameFilter = name?.trim() ?? '';
    departmentFilter = department?.trim() ?? '';
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    nameFilter = '';
    departmentFilter = '';
    notifyListeners();
  }

  /// Stream of all doctors
  Stream<QuerySnapshot> get doctorsStream =>
      _firestore.collection('doctors').snapshots();

  /// Fetch all online clinics for a doctor
  Future<List<DoctorOnlineClinicModel>> getDoctorClinics(
      QueryDocumentSnapshot doctorDoc) async {
    final doctorId = doctorDoc.id;
    final data = doctorDoc.data() as Map<String, dynamic>;

    final clinicsSnap = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .get();

    if (clinicsSnap.docs.isEmpty) return [];

    return clinicsSnap.docs.map((clinicDoc) {
      final c = clinicDoc.data();

      final slots = (c['slots'] as List? ?? []).map((s) {
        // Use the model's AppointmentSlot
        return AppointmentSlot(
          start: s['start'],
          end: s['end'],
        );
      }).toList();

      return DoctorOnlineClinicModel(
        id: clinicDoc.id,
        doctorId: doctorId,
        doctorName: data['name'] ?? 'Unknown',
        doctorQualification: '', // Not used
        department: c['department'] ?? '',
        startTime: c['startTime'] ?? '',
        endTime: c['endTime'] ?? '',
        fees: c['fees'] ?? 0,
        appointmentDuration: c['appointmentDuration'] ?? 15,
        bufferDuration: c['bufferDuration'] ?? 0,
        days: List<String>.from(c['days'] ?? []),
        slots: slots,
      );
    }).toList();
  }

  /// Search filter (name + department)
  bool matchesSearch(
      String doctorName, List<DoctorOnlineClinicModel> clinics) {
    final nameQuery = nameFilter.toLowerCase();
    final deptQuery = departmentFilter.toLowerCase();

    final nameMatch =
    nameQuery.isEmpty ? true : doctorName.toLowerCase().contains(nameQuery);

    final deptMatch = deptQuery.isEmpty
        ? true
        : clinics.any((c) => c.department.toLowerCase().contains(deptQuery));

    return nameMatch && deptMatch;
  }
}
