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
  final String smsApiKey = 'ee3c7010a3b059e955c1d1ffd8805e0d27b940ecc4240ca0';

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
      await docRef.update({'status': 'accepted'});

      final appointmentDoc = await docRef.get();
      final patientId = appointmentDoc['patientId'] ?? '';

      if (patientId.isNotEmpty) {
        final patientDoc =
        await _firestore.collection('patients').doc(patientId).get();

        if (patientDoc.exists) {
          final patientData = patientDoc.data()!;
          final phone = patientData['phoneNumber'] ?? '';
          final name = patientData['name'] ?? 'Patient';

          print('📞 Patient phone: $phone');

          final clinicDoc = await _firestore
              .collection('doctors')
              .doc(doctorId)
              .collection('online_clinics')
              .doc(clinicId)
              .get();

          final clinicData = clinicDoc.data()!;
          final startTime = clinicData['startTime'] ?? '';
          final endTime = clinicData['endTime'] ?? '';

          if (phone.isNotEmpty) {
            smsSent = await _sendSms(
              phone: phone,
              message:
              "Hello $name, your appointment has been confirmed. ",
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

  /// 🔹 Send SMS via SMSMobileAPI (direct API key)
  Future<bool> _sendSms({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse(
      'https://api.smsmobileapi.com/sendsms'
          '?apikey=$smsApiKey'
          '&recipients=${phone.replaceAll('+', '')}' // numeric only
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

    final doc = await _firestore.collection('patients').doc(patientId).get();

    if (doc.exists) {
      final ref = doc.data()?['referenceNumber'] ?? 'N/A';
      patientRefs[patientId] = ref;
      return ref;
    }

    return 'N/A';
  }
}
