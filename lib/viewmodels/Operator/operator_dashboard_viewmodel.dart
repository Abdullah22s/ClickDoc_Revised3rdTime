import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OperatorDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSubmitting = false;

  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> currentAppointments = []; // Waiting for vitals
  List<Map<String, dynamic>> pastAppointments = [];    // Vitals completed

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  Timer? _timer;
  StreamSubscription? _subscription;

  OperatorDashboardViewModel() {
    _listenToAppointments();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _filterAndSortAppointments());
  }

  // Update date and re-filter
  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    _filterAndSortAppointments();
  }

  void _listenToAppointments() {
    // Removed the vitalsEntered filter so we can get BOTH Current and Past
    _subscription = _firestore
        .collectionGroup('appointments')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) async {

      final List<Map<String, dynamic>> enrichedList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        Timestamp? startTimestamp = data['startDateTime'] as Timestamp?;
        if (startTimestamp == null) continue;

        final String patientId = data['patientId'] ?? "";

        // 🟢 THE FIX: If doctorId isn't explicitly in the document, extract it from the path!
        String doctorId = data['doctorId'] ?? "";
        if (doctorId.isEmpty) {
          final pathSegments = doc.reference.path.split('/');
          // Path format: doctors/{doctorId}/online_clinics/{clinicId}/appointments/{appId}
          if (pathSegments.length >= 2 && pathSegments[0] == 'doctors') {
            doctorId = pathSegments[1];
          }
        }

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

    // 1. Filter CURRENT (No vitals, 30m window)
    currentAppointments = _allAppointments.where((app) {
      final bool vitalsDone = app['vitalsEntered'] ?? false;
      if (vitalsDone) return false;

      final DateTime startTime = (app['displayStartTime'] as Timestamp).toDate();
      final int difference = startTime.difference(now).inMinutes;

      return difference <= 30 && difference > -60;
    }).toList();

    // 2. Filter PAST (Vitals completed, Filtered by Selected Date)
    pastAppointments = _allAppointments.where((app) {
      final bool vitalsDone = app['vitalsEntered'] ?? false;
      if (!vitalsDone) return false;

      final DateTime startTime = (app['displayStartTime'] as Timestamp).toDate();

      // Match only the Year, Month, and Day
      return startTime.year == _selectedDate.year &&
          startTime.month == _selectedDate.month &&
          startTime.day == _selectedDate.day;
    }).toList();

    // Sort both
    currentAppointments.sort((a, b) => (a['displayStartTime'] as Timestamp).compareTo(b['displayStartTime'] as Timestamp));
    pastAppointments.sort((a, b) => (b['displayStartTime'] as Timestamp).compareTo(a['displayStartTime'] as Timestamp));

    isLoading = false;
    notifyListeners();
  }

  // ... (Keep _fetchNames and submitVitals the same as before) ...

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

      // 🟢 THE FIX: Manually update the local list immediately so the UI jumps without waiting
      final index = _allAppointments.indexWhere((app) => app['appointmentRef'] == appointmentRef);
      if (index != -1) {
        _allAppointments[index]['vitalsEntered'] = true;
      }

      // Force the re-sort and re-filter immediately
      _filterAndSortAppointments();

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