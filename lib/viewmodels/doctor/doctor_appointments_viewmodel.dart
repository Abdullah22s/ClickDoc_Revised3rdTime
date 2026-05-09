import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/doctor/appointment_model.dart';

class DoctorAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  List<DoctorAppointment> appointments = [];
  bool isLoading = true;

  /// Cache patient reference numbers
  final Map<String, String> patientRefs = {};

  /// 🔹 Direct SMSMobileAPI key
  final String smsApiKey =
      'ee3c7010a3b059e955c1d1ffd8805e0d27b940ecc4240ca0';

  DoctorAppointmentsViewModel() {
    fetchAppointments();
  }

  void fetchAppointments() {
    _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final now = DateTime.now();

      /// Auto-delete expired clinics
      for (var doc in snapshot.docs) {
        final endDateTime = doc['endDateTime'] as Timestamp?;
        if (endDateTime != null && endDateTime.toDate().isBefore(now)) {
          await doc.reference.delete();
        }
      }

      /// Keep only upcoming clinics
      appointments = snapshot.docs
          .where((doc) {
        final endDateTime = doc['endDateTime'] as Timestamp?;
        return endDateTime != null && endDateTime.toDate().isAfter(now);
      })
          .map(
            (doc) => DoctorAppointment.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        ),
      )
          .toList();

      isLoading = false;
      notifyListeners();
    });
  }

  /// Accept / Reject Appointment
  /// Returns true if SMS was sent successfully
  Future<bool> handleAppointment({
    required String clinicId,
    required String appointmentId,
    required String action,
  }) async {
    final docRef = _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .doc(clinicId)
        .collection('appointments')
        .doc(appointmentId);

    bool smsSent = false;

    if (action == 'accept') {
      // 1. Get the appointment data
      final appointmentDoc = await docRef.get();
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>? ?? {};
      final patientId = appointmentData['patientId'] ?? '';
      final String slotStart = appointmentData['start'] ?? '00:00';
      final String slotEnd = appointmentData['end'] ?? '00:00';

      // 2. Fetch the clinic details FIRST to get the date
      final clinicDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .doc(clinicId)
          .get();

      final clinicData = clinicDoc.data() ?? {};
      final Timestamp? clinicDateTs = clinicData['startDateTime'] as Timestamp?;

      // 3. Calculate exact startDateTime to save for the Operator
      DateTime? exactStartDateTime;
      if (clinicDateTs != null) {
        try {
          final date = clinicDateTs.toDate();
          final rawTime = slotStart.toUpperCase().replaceAll('AM', '').replaceAll('PM', '').trim();
          final parts = rawTime.split(':');
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          if (slotStart.toUpperCase().contains('PM') && hour != 12) hour += 12;
          if (slotStart.toUpperCase().contains('AM') && hour == 12) hour = 0;

          exactStartDateTime = DateTime(date.year, date.month, date.day, hour, minute);
        } catch (e) {
          exactStartDateTime = clinicDateTs.toDate();
        }
      }

      // 4. Update status and save the exact startDateTime so Operator can filter it
      await docRef.update({
        'status': 'accepted',
        'vitalsEntered': false, // 🟢 Ensures operator can find this in their query
        if (exactStartDateTime != null) 'startDateTime': Timestamp.fromDate(exactStartDateTime),
      });

      if (patientId.isNotEmpty) {
        final patientDoc = await _firestore.collection('patients').doc(patientId).get();

        if (patientDoc.exists) {
          final patientData = patientDoc.data()!;
          final phone = patientData['phoneNumber'] ?? '';
          final name = patientData['name'] ?? 'Patient';
          final referenceNumber = patientData['referenceNumber'] ?? '';

          // 5. Add to history WITH the slot times and date so "Current Patients" tab works
          await _firestore.collection('doctor_patient_history').add({
            'doctorId': doctorId,
            'patientId': patientId,
            'referenceNumber': referenceNumber,
            'department': clinicData['department'] ?? 'General',
            'appointmentDate': clinicData['startDateTime'], // Required for date filtering
            'slotStart': slotStart,
            'slotEnd': slotEnd,
            'acceptedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });

          print("✅ Patient added to history");
          print('📞 Patient phone: $phone');

          if (phone.isNotEmpty) {
            smsSent = await _sendSms(
              phone: phone,
              message: "Hello $name, your appointment has been confirmed.",
            );
          } else {
            print('❌ Phone number is empty');
          }
        }
      }
    } else if (action == 'reject') {
      await docRef.delete();
    }

    notifyListeners();
    return smsSent;
  }

  // 🟢 NEW: Start the appointment
  Future<void> startAppointment(String clinicId, String appointmentId) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .doc(clinicId)
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'in_progress'});

      notifyListeners();
    } catch (e) {
      debugPrint("Error starting appointment: $e");
    }
  }

  // 🔴 NEW: End the appointment (Deletes the slot)
  Future<void> endAppointment(String clinicId, String appointmentId) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .doc(clinicId)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      notifyListeners();
    } catch (e) {
      debugPrint("Error ending appointment: $e");
    }
  }

  /// 🔹 Send SMS via SMSMobileAPI (direct API key)
  Future<bool> _sendSms({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse(
      'https://api.smsmobileapi.com/sendsms'
          '?apikey=$smsApiKey'
          '&recipients=${phone.replaceAll('+', '')}'
          '&message=${Uri.encodeComponent(message)}'
          '&sendsms=1',
    );

    try {
      final response = await http.get(uri);

      print('📨 SMS status: ${response.statusCode}');
      print('📨 SMS response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ SMS exception: $e');
      return false;
    }
  }

  /// Get patient reference number
  Future<String> getPatientReference(String patientId) async {
    if (patientRefs.containsKey(patientId)) {
      return patientRefs[patientId]!;
    }

    final doc =
    await _firestore.collection('patients').doc(patientId).get();

    if (doc.exists) {
      final ref = doc.data()?['referenceNumber'] ?? 'N/A';
      patientRefs[patientId] = ref;
      return ref;
    }

    return 'N/A';
  }
}