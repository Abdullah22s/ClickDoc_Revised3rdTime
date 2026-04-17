import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorCurrentPatientsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  /// ✅ FIX: removed orderBy to prevent Firestore flicker issue
  Stream<QuerySnapshot> getPatientsStream() {
    return _firestore
        .collection('doctor_patient_history')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }
}