import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientPrescriptionsViewModel extends ChangeNotifier {
  final String userEmail;

  bool isLoading = true;
  String? _patientId;

  PatientPrescriptionsViewModel({required this.userEmail}) {
    _init();
  }

  Future<void> _init() async {
    await _fetchPatientId();
  }

  /// Finds the patient document ID based on the user's email
  Future<void> _fetchPatientId() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        _patientId = query.docs.first.id;
      }
    } catch (e) {
      debugPrint("Error fetching patient ID: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Returns a stream of grouped prescriptions
  /// Key: Doctor's Name, Value: List of their prescriptions sorted by date
  Stream<Map<String, List<QueryDocumentSnapshot>>> getGroupedPrescriptionsStream() {
    if (_patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('prescriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {

      // Grouping the documents by doctorName
      Map<String, List<QueryDocumentSnapshot>> groupedData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Ensure you are saving 'doctorName' when the doctor creates a prescription
        final doctorName = data['doctorName'] ?? 'Unknown Doctor';

        if (!groupedData.containsKey(doctorName)) {
          groupedData[doctorName] = [];
        }
        groupedData[doctorName]!.add(doc);
      }

      return groupedData;
    });
  }

  /// Opens image/pdf prescriptions using the device's native browser/viewer
  Future<void> openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Open error: $e");
    }
  }

  String? get patientId => _patientId;
}