import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient/patient_physical_opd_model.dart';

class PatientPhysicalOpdViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, DoctorPhysicalOpdModel> doctorCache = {};
  Map<String, bool> expandedDoctor = {};

  final List<String> daysOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Toggle doctor expansion
  void toggleDoctorExpansion(String doctorId) {
    expandedDoctor[doctorId] = !(expandedDoctor[doctorId] ?? false);
    notifyListeners();
  }

  /// Fetch doctor info and their OPDs
  Future<DoctorPhysicalOpdModel?> getDoctorInfo(String doctorUid) async {
    if (doctorCache.containsKey(doctorUid)) return doctorCache[doctorUid]!;

    final doc = await _firestore.collection('doctors').doc(doctorUid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final name = data['name'] ?? 'Unknown';
    final qualifications = List<String>.from(data['qualifications'] ?? []);

    final opdSnapshot = await _firestore
        .collection('doctors')
        .doc(doctorUid)
        .collection('physical_opds')
        .get();

    if (opdSnapshot.docs.isEmpty) return null; // skip doctor if no OPDs

    final opds = opdSnapshot.docs
        .map((d) => PhysicalOpdModel.fromMap(d.data()))
        .toList();

    opds.sort((a, b) => daysOrder.indexOf(a.day).compareTo(daysOrder.indexOf(b.day)));

    final doctor = DoctorPhysicalOpdModel.fromMap(doctorUid, name, qualifications, opds);
    doctorCache[doctorUid] = doctor;
    return doctor;
  }

  /// Stream all doctors with their OPDs
  Stream<List<DoctorPhysicalOpdModel>> get doctorOpdStream async* {
    await for (final snapshot in _firestore.collection('doctors').snapshots()) {
      final List<DoctorPhysicalOpdModel> doctors = [];
      for (var doc in snapshot.docs) {
        final doctor = await getDoctorInfo(doc.id);
        if (doctor != null) doctors.add(doctor);
      }
      yield doctors;
    }
  }
}
