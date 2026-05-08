import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OperatorDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isSubmitting = false;

  Stream<List<Map<String, dynamic>>> getEnrichedAppointments() {
    return _firestore
        .collectionGroup('appointments')
        .where('status', isEqualTo: 'accepted')
        .where('vitalsEntered', isEqualTo: false)
        .snapshots()
        .asyncMap((QuerySnapshot snapshot) async {

      final List<Map<String, dynamic>> enrichedList = [];
      final DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // ✅ FIX: Look for startDateTime inside the 'slots' array
        Timestamp? startTimestamp;

        if (data['startDateTime'] != null) {
          startTimestamp = data['startDateTime'] as Timestamp;
        } else if (data['slots'] != null && (data['slots'] as List).isNotEmpty) {
          // Access the first slot's startDateTime
          startTimestamp = data['slots'][0]['startDateTime'] as Timestamp?;
        }

        if (startTimestamp == null) continue;

        final DateTime startTime = startTimestamp.toDate();
        final int difference = startTime.difference(now).inMinutes;

        // Condition: 30 mins before to 60 mins after
        if (difference <= 30 && difference > -60) {
          final String patientId = data['patientId'] ?? "";
          final String doctorId = data['doctorId'] ?? "";

          final names = await _fetchNames(doctorId, patientId);

          enrichedList.add({
            ...data,
            'appointmentRef': doc.reference,
            'doctorName': names['doctorName'],
            'patientName': names['patientName'],
            'displayStartTime': startTimestamp, // Store for sorting
          });
        }
      }

      // Sort: Soonest first
      enrichedList.sort((a, b) =>
          (a['displayStartTime'] as Timestamp).compareTo(b['displayStartTime'] as Timestamp));

      return enrichedList;
    });
  }

  Future<Map<String, String>> _fetchNames(String docId, String patientId) async {
    String drName = "Unknown Doctor";
    String ptName = "Unknown Patient";
    try {
      final results = await Future.wait([
        if (docId.isNotEmpty) _firestore.collection('doctors').doc(docId).get(),
        if (patientId.isNotEmpty) _firestore.collection('patients').doc(patientId).get(),
      ]);
      if (results[0] != null && results[0]!.exists) {
        drName = (results[0]!.data() as Map<String, dynamic>)['name'] ?? drName;
      }
      if (results[1] != null && results[1]!.exists) {
        ptName = (results[1]!.data() as Map<String, dynamic>)['name'] ?? ptName;
      }
    } catch (e) {
      debugPrint("Error fetching names: $e");
    }
    return {'doctorName': drName, 'patientName': ptName};
  }

  Future<String?> submitVitals({
    required DocumentReference appointmentRef,
    required String bp,
    required String temp,
    required String spo2,
  }) async {
    if (bp.trim().isEmpty || temp.trim().isEmpty || spo2.trim().isEmpty) {
      return "Please fill all fields.";
    }
    isSubmitting = true;
    notifyListeners();
    try {
      await appointmentRef.update({
        'vitalsEntered': true,
        'vitals': {'bp': bp.trim(), 'temp': temp.trim(), 'spo2': spo2.trim()}
      });
      isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      return "Error: $e";
    }
  }
}