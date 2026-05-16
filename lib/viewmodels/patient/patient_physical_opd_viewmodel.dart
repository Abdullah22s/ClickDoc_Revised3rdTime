import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient/patient_physical_opd_model.dart'; // Adjust import if needed

class PatientPhysicalOpdViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> expandedDoctor = {};
  String nameFilter = '';
  String departmentFilter = '';

  final List<String> daysOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

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

  /// Fetch all physical opds for a doctor
  /// Fetch all physical opds for a doctor
  Future<List<PhysicalOpdModel>> getDoctorOpds(
      QueryDocumentSnapshot doctorDoc) async {
    final doctorId = doctorDoc.id;

    final opdsSnap = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .get();

    if (opdsSnap.docs.isEmpty) return [];

    final opds = opdsSnap.docs.map((opdDoc) {
      // ✅ FIXED: Passing both opdDoc.id and the data map
      return PhysicalOpdModel.fromMap(opdDoc.id, opdDoc.data() as Map<String, dynamic>);
    }).toList();

    // Sort the OPDs by day of the week
    opds.sort((a, b) => daysOrder.indexOf(a.day).compareTo(daysOrder.indexOf(b.day)));

    return opds;
  }

  /// Search filter (name + department)
  bool matchesSearch(
      String doctorName, List<PhysicalOpdModel> opds) {
    final nameQuery = nameFilter.toLowerCase();
    final deptQuery = departmentFilter.toLowerCase();

    final nameMatch =
    nameQuery.isEmpty ? true : doctorName.toLowerCase().contains(nameQuery);

    final deptMatch = deptQuery.isEmpty
        ? true
        : opds.any((o) => o.department.toLowerCase().contains(deptQuery));

    return nameMatch && deptMatch;
  }
}