import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/patient/patient_model.dart';

class DoctorPatientProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PatientModel? patient;
  bool isLoading = true;

  String? _patientId; // ✅ ADD THIS

  /// =========================
  /// FETCH PATIENT
  /// =========================
  Future<void> fetchPatientByReferenceNumber(String referenceNumber) async {
    isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('referenceNumber', isEqualTo: referenceNumber.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;

        _patientId = doc.id; // ✅ STORE ID
        patient = PatientModel.fromMap(doc.id, doc.data());
      } else {
        patient = null;
        _patientId = null;
        debugPrint("Patient not found");
      }
    } catch (e) {
      debugPrint("Error fetching patient: $e");
      patient = null;
      _patientId = null;
    }

    isLoading = false;
    notifyListeners();
  }

  /// =========================
  /// STREAM REPORTS (NEW)
  /// =========================
  Stream<QuerySnapshot> getReportsStream() {
    if (_patientId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('patients')
        .doc(_patientId)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// OPEN REPORT (NEW)
  /// =========================
  Future<void> openReport(String url) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint("Could not launch URL");
      }
    } catch (e) {
      debugPrint("Open report error: $e");
    }
  }
}