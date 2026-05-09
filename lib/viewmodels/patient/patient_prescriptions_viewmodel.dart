import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientPrescriptionsViewModel extends ChangeNotifier {
  final String userEmail;

  bool isLoading = true;
  String? _patientId;

  // 🟢 NEW: Cache for doctor names to avoid "Unknown Doctor"
  final Map<String, String> _doctorNameCache = {};

  PatientPrescriptionsViewModel({required this.userEmail}) {
    _init();
  }

  Future<void> _init() async {
    await _fetchPatientId();
  }

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

  // 🟢 NEW: Method to fetch a doctor's name by ID
  Future<String> getDoctorName(String doctorId) async {
    if (_doctorNameCache.containsKey(doctorId)) return _doctorNameCache[doctorId]!;

    try {
      final doc = await FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
      final name = doc.data()?['name'] ?? 'Unknown Doctor';
      _doctorNameCache[doctorId] = name;
      return name;
    } catch (e) {
      return 'Unknown Doctor';
    }
  }

  Stream<Map<String, List<QueryDocumentSnapshot>>> getGroupedPrescriptionsStream() {
    if (_patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('prescriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      Map<String, List<QueryDocumentSnapshot>> groupedData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // 🟢 Group by doctorId instead of a missing doctorName field
        final docId = data['doctorId'] ?? 'Unknown';

        if (!groupedData.containsKey(docId)) {
          groupedData[docId] = [];
        }
        groupedData[docId]!.add(doc);
      }
      return groupedData;
    });
  }

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