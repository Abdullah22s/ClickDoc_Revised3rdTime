import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/doctor/appointment_model.dart';

class DoctorAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  List<DoctorAppointment> appointments = [];
  bool isLoading = true;

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
          .map((doc) => DoctorAppointment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      isLoading = false;
      notifyListeners();
    });
  }
}
