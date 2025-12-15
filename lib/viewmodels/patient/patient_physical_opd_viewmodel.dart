import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient/patient_physical_opd_model.dart'; // Only patient model

class PatientPhysicalOpdViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, DoctorPhysicalOpdModel> doctorCache = {};
  Map<String, bool> expandedDoctor = {};
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  final List<String> daysOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

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

  /// Fetch doctor info and their OPDs
  Future<DoctorPhysicalOpdModel> getDoctorInfo(String doctorUid) async {
    if (doctorCache.containsKey(doctorUid)) return doctorCache[doctorUid]!;

    final doc = await _firestore.collection('doctors').doc(doctorUid).get();
    final name = doc.exists ? doc['name'] ?? 'Unknown' : 'Unknown';

    final opdSnapshot = await _firestore
        .collection('doctors')
        .doc(doctorUid)
        .collection('physical_opds')
        .get();

    final opds = opdSnapshot.docs
        .map((d) => PhysicalOpdModel.fromMap(d.data()))
        .toList();

    opds.sort((a, b) => daysOrder.indexOf(a.day)
        .compareTo(daysOrder.indexOf(b.day)));

    final doctor = DoctorPhysicalOpdModel.fromMap(doctorUid, name, opds);
    doctorCache[doctorUid] = doctor;
    return doctor;
  }

  /// Stream all doctors with their OPDs
  Stream<List<DoctorPhysicalOpdModel>> get doctorOpdStream async* {
    await for (final snapshot in _firestore.collection('doctors').snapshots()) {
      final List<DoctorPhysicalOpdModel> doctors = [];
      for (var doc in snapshot.docs) {
        final doctor = await getDoctorInfo(doc.id);
        doctors.add(doctor);
      }
      yield doctors;
    }
  }

  /// Search filter
  bool matchesSearch(DoctorPhysicalOpdModel doctor) {
    if (searchQuery.isEmpty) return true;
    final query = searchQuery.toLowerCase();

    if (doctor.name.toLowerCase().contains(query)) return true;

    for (var opd in doctor.opds) {
      if (opd.department.toLowerCase().contains(query) ||
          opd.hospitalName.toLowerCase().contains(query)) {
        return true;
      }
    }

    return false;
  }
}
