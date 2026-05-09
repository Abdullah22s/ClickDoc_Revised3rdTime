import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DoctorCurrentPatientsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 🟢 NEW: Cache to store fetched patient names to reduce Firestore reads
  final Map<String, String> _patientNameCache = {};

  Stream<QuerySnapshot>? _cachedStream;

  Stream<QuerySnapshot> get patientsStream {
    _cachedStream ??= _buildPatientsStream();
    return _cachedStream!;
  }

  void updateDate(DateTime newDate) {
    _selectedDate = newDate;
    _cachedStream = _buildPatientsStream();
    notifyListeners();
  }

  Stream<QuerySnapshot> _buildPatientsStream() {
    DateTime startOfPeriod = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfPeriod = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return _firestore
        .collection('doctor_patient_history')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPeriod))
        .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfPeriod))
        .snapshots();
  }

  // 🟢 NEW: Helper to get name from cache or Firestore
  Future<String> getPatientName(String patientId) async {
    if (_patientNameCache.containsKey(patientId)) return _patientNameCache[patientId]!;

    final doc = await _firestore.collection('patients').doc(patientId).get();
    if (doc.exists) {
      final name = doc.data()?['name'] ?? 'Unknown Patient';
      _patientNameCache[patientId] = name;
      return name;
    }
    return 'Unknown Patient';
  }

  Future<void> savePrescription({
    required String patientId,
    String? prescriptionText,
    File? prescriptionImageFile,
  }) async {
    try {
      String? prescriptionImageUrl;

      if (prescriptionImageFile != null) {
        final fileName = 'rx_history_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('prescriptions')
            .child(patientId)
            .child(fileName);

        final uploadTask = await storageRef.putFile(
          prescriptionImageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        ).timeout(const Duration(seconds: 30));

        prescriptionImageUrl = await uploadTask.ref.getDownloadURL();
      }

      if (prescriptionText != null || prescriptionImageUrl != null) {
        await _firestore
            .collection('patients')
            .doc(patientId)
            .collection('prescriptions')
            .add({
          'doctorId': doctorId,
          'createdAt': FieldValue.serverTimestamp(),
          'prescriptionText': prescriptionText,
          'prescriptionImageUrl': prescriptionImageUrl,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error in history savePrescription: $e");
      rethrow;
    }
  }
}