import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OperatorDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSubmitting = false;

  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> visibleAppointments = [];

  Timer? _timer;
  StreamSubscription? _subscription;

  OperatorDashboardViewModel() {
    _listenToAppointments();
    // 🟢 TIMER: Runs every 60 seconds to check if any appointment entered the 30-min window
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _filterAndSortAppointments());
  }

  void _listenToAppointments() {
    _subscription = _firestore
        .collectionGroup('appointments')
        .where('status', isEqualTo: 'accepted')
        .where('vitalsEntered', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {

      final List<Map<String, dynamic>> enrichedList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Now reliably available because Doctor ViewModel saves it on Accept!
        Timestamp? startTimestamp = data['startDateTime'] as Timestamp?;

        if (startTimestamp == null) continue;

        final String patientId = data['patientId'] ?? "";
        final String doctorId = data['doctorId'] ?? "";

        final names = await _fetchNames(doctorId, patientId);

        enrichedList.add({
          ...data,
          'appointmentRef': doc.reference,
          'doctorName': names['doctorName'],
          'patientName': names['patientName'],
          'displayStartTime': startTimestamp,
        });
      }

      _allAppointments = enrichedList;
      _filterAndSortAppointments();
    });
  }

  void _filterAndSortAppointments() {
    final DateTime now = DateTime.now();

    visibleAppointments = _allAppointments.where((app) {
      final startTimestamp = app['displayStartTime'] as Timestamp;
      final DateTime startTime = startTimestamp.toDate();
      final int difference = startTime.difference(now).inMinutes;

      // Condition: Shows up at 30 mins remaining, stays until 60 mins past
      return difference <= 30 && difference > -60;
    }).toList();

    // Sort: Soonest first
    visibleAppointments.sort((a, b) =>
        (a['displayStartTime'] as Timestamp).compareTo(b['displayStartTime'] as Timestamp));

    isLoading = false;
    notifyListeners(); // 🟢 Forces UI update
  }

  Future<Map<String, String>> _fetchNames(String docId, String patientId) async {
    String drName = "Unknown Doctor";
    String ptName = "Unknown Patient";
    try {
      if (docId.isNotEmpty) {
        final docSnap = await _firestore.collection('doctors').doc(docId).get();
        if (docSnap.exists) drName = docSnap.data()?['name'] ?? drName;
      }
      if (patientId.isNotEmpty) {
        final ptSnap = await _firestore.collection('patients').doc(patientId).get();
        if (ptSnap.exists) ptName = ptSnap.data()?['name'] ?? ptName;
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

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}