import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/doctor/appointment_model.dart';

class DoctorAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  List<DoctorAppointment> appointments = [];
  bool isLoading = true;

  // Map to cache patient reference numbers
  final Map<String, String> patientRefs = {};

  DoctorAppointmentsViewModel() {
    fetchAppointments();
  }

  void fetchAppointments() {
    _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      appointments = snapshot.docs
          .map((doc) => DoctorAppointment.fromMap(
          doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      isLoading = false;
      notifyListeners();
    });
  }

  /// Handle Accept/Reject
  Future<void> handleAppointment({
    required String clinicId,
    required String appointmentId,
    required String action, // 'accept' or 'reject'
  }) async {
    final docRef = _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .doc(clinicId)
        .collection('appointments')
        .doc(appointmentId);

    if (action == 'accept') {
      await docRef.update({'status': 'accepted'});
    } else if (action == 'reject') {
      await docRef.delete(); // delete rejected requests
    }

    notifyListeners();
  }

  /// Get patient reference number from patients collection
  Future<String> getPatientReference(String patientId) async {
    if (patientRefs.containsKey(patientId)) {
      return patientRefs[patientId]!;
    }

    final doc = await _firestore.collection('patients').doc(patientId).get();
    if (doc.exists) {
      final ref = doc.data()?['referenceNumber'] ?? 'N/A';
      patientRefs[patientId] = ref;
      return ref;
    }

    return 'N/A';
  }
}
