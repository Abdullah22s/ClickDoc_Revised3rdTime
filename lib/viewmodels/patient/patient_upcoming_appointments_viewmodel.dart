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

  bool _isOnlineAppointment(DocumentReference ref) {
    // Correct online appointment path:
    // doctors/{doctorId}/online_clinics/{clinicId}/appointments/{appointmentId}

    final pathSegments = ref.path.split('/');

    return pathSegments.contains('online_clinics');
  }

  void _listenToMyAppointments() {
    _subscription = _firestore
        .collectionGroup('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('status', whereIn: ['accepted', 'in_progress'])
        .snapshots()
        .listen((snapshot) async {
      final List<Map<String, dynamic>> list = [];

      for (var doc in snapshot.docs) {
        // ✅ IMPORTANT FIX:
        // Ignore physical OPD appointments here.
        // This screen is only for online appointments.
        if (!_isOnlineAppointment(doc.reference)) {
          continue;
        }

        final data = doc.data();

        String doctorName = data['doctorName'] ?? "Doctor";

        if (data['doctorName'] == null) {
          final pathSegments = doc.reference.path.split('/');

          // Path:
          // doctors/{doctorId}/online_clinics/{clinicId}/appointments/{appointmentId}
          final docId = pathSegments[1];

          final drDoc = await _firestore.collection('doctors').doc(docId).get();
          doctorName = drDoc.data()?['name'] ?? "Doctor";
        }

        list.add({
          ...data,
          'id': doc.id,
          'reference': doc.reference,
          'doctorName': doctorName,
          'appointmentSource': 'online',
        });
      }

      upcomingAppointments = list;
      _filterAppointments();
    });
  }

  void _filterAppointments() {
    final now = DateTime.now();

    upcomingAppointments = upcomingAppointments.where((app) {
      // Extra safety check:
      // Only keep online appointments in this screen.
      final ref = app['reference'];
      if (ref is DocumentReference && !_isOnlineAppointment(ref)) {
        return false;
      }

      // 1. If session is already in progress, always show it.
      if (app['status'] == 'in_progress') return true;

      // 2. If vitals are entered but status is still accepted.
      if (app['vitalsEntered'] == true && app['status'] == 'accepted') {
        return true;
      }

      // 3. If vitals not entered, show within the 30-min window.
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
    if (bp.isEmpty || temp.isEmpty || spo2.isEmpty) {
      return "Please fill all fields";
    }

    // ✅ Safety check:
    // Do not submit vitals from online upcoming screen to physical appointment.
    if (!_isOnlineAppointment(ref)) {
      return "Invalid appointment type for online session.";
    }

    isSubmitting = true;
    notifyListeners();

    try {
      await ref.update({
        'vitalsEntered': true,
        'vitals': {
          'bp': bp.trim(),
          'temp': temp.trim(),
          'spo2': spo2.trim(),
        }
      });

      isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
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