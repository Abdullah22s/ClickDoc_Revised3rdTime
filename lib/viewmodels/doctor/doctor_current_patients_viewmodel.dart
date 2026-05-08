import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorCurrentPatientsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  // Default to today
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void updateDate(DateTime newDate) {
    _selectedDate = newDate;
    notifyListeners();
  }

  Stream<QuerySnapshot> getPatientsStream() {
    // Calculate start and end of the chosen date
    DateTime startOfPeriod = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfPeriod = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return _firestore
        .collection('doctor_patient_history')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPeriod))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfPeriod))
        .snapshots();
  }
}