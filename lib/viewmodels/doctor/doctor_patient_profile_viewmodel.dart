import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/patient/patient_model.dart';

class DoctorPatientProfileViewModel extends ChangeNotifier {
  final String doctorName;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PatientModel? patient;
  bool isLoading = false;
  String? _patientId;

  // Added report categories to match the patient side
  final List<String> reportCategories = [
    'Blood Report',
    'Diabetic Report',
    'Radiology (X-Ray/MRI)',
    'Prescription',
    'Other'
  ];

  DoctorPatientProfileViewModel({required this.doctorName});

  // =========================
  // FETCH PATIENT
  // =========================
  Future<void> fetchPatientByReferenceNumber(String referenceNumber) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _firestore
          .collection('patients')
          .where('referenceNumber', isEqualTo: referenceNumber.trim())
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final doc = result.docs.first;
        _patientId = doc.id;
        patient = PatientModel.fromMap(doc.id, doc.data());
      } else {
        _patientId = null;
        patient = null;
      }
    } catch (e) {
      debugPrint("❌ fetch error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // =========================
  // FETCH REPORTS
  // =========================
  Stream<QuerySnapshot> getReportsStream() {
    if (_patientId == null) return const Stream.empty();
    return _firestore
        .collection('patients')
        .doc(_patientId)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // =========================
  // OPEN FILE
  // =========================
  Future<void> openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("❌ open error: $e");
    }
  }

  String? get patientId => _patientId;
}