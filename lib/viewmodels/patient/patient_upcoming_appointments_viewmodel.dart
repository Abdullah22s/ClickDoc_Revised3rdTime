import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientUpcomingAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String patientId = FirebaseAuth.instance.currentUser!.uid;

  bool isLoading = true;
  bool isSubmitting = false;

  List<Map<String, dynamic>> upcomingAppointments = [];
  Timer? _timer;
  StreamSubscription? _subscription;

  PatientUpcomingAppointmentsViewModel() {
    _listenToMyAppointments();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _filterAppointments());
  }

  void _listenToMyAppointments() {
    _subscription = _firestore
        .collectionGroup('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('status', whereIn: ['accepted', 'in_progress']) // ✅ Listen for both
        .snapshots()
        .listen((snapshot) async {
      final List<Map<String, dynamic>> list = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();

        String doctorName = data['doctorName'] ?? "Doctor";
        if (data['doctorName'] == null) {
          final pathSegments = doc.reference.path.split('/');
          final docId = pathSegments[1];
          final drDoc = await _firestore.collection('doctors').doc(docId).get();
          doctorName = drDoc.data()?['name'] ?? "Doctor";
        }

        list.add({
          ...data,
          'id': doc.id,
          'reference': doc.reference,
          'doctorName': doctorName,
        });
      }

      upcomingAppointments = list;
      _filterAppointments();
    });
  }

  void _filterAppointments() {
    final now = DateTime.now();

    upcomingAppointments = upcomingAppointments.where((app) {
      // 1. If session is already in progress, always show it (Join button)
      if (app['status'] == 'in_progress') return true;

      // 2. If vitals are entered but status is still 'accepted' (Waiting state)
      if (app['vitalsEntered'] == true && app['status'] == 'accepted') return true;

      // 3. If vitals not entered, show within the 30-min window
      final Timestamp? startTs = app['startDateTime'] as Timestamp?;
      if (startTs == null) return true;

      final startTime = startTs.toDate();
      final difference = startTime.difference(now).inMinutes;

      return difference <= 30 && difference > -60;
    }).toList();

    isLoading = false;
    notifyListeners();
  }

  Future<String?> submitMyVitals({
    required DocumentReference ref,
    required String bp,
    required String temp,
    required String spo2,
  }) async {
    if (bp.isEmpty || temp.isEmpty || spo2.isEmpty) return "Please fill all fields";

    isSubmitting = true;
    notifyListeners();

    try {
      await ref.update({
        'vitalsEntered': true,
        'vitals': {'bp': bp.trim(), 'temp': temp.trim(), 'spo2': spo2.trim()}
      });
      isSubmitting = false;
      return null;
    } catch (e) {
      isSubmitting = false;
      return e.toString();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}