import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/doctor/appointment_model.dart';

class DoctorAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  List<DoctorAppointment> appointments = [];
  bool isLoading = true;

  final Map<String, String> patientRefs = {};

  /// 🔹 SMS API Key preserved
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

      for (var doc in snapshot.docs) {
        final endDateTime = doc['endDateTime'] as Timestamp?;
        if (endDateTime != null && endDateTime.toDate().isBefore(now)) {
          await doc.reference.delete();
        }
      }

      appointments = snapshot.docs
          .where((doc) {
        final endDateTime = doc['endDateTime'] as Timestamp?;
        return endDateTime != null && endDateTime.toDate().isAfter(now);
      })
          .map((doc) => DoctorAppointment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      isLoading = false;
      notifyListeners();
    });
  }

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
      final appointmentDoc = await docRef.get();
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>? ?? {};
      final patientId = appointmentData['patientId'] ?? '';
      final String slotStart = appointmentData['start'] ?? '00:00';
      final String slotEnd = appointmentData['end'] ?? '00:00';

      final clinicDoc = await _firestore.collection('doctors').doc(doctorId).collection('online_clinics').doc(clinicId).get();
      final clinicData = clinicDoc.data() ?? {};
      final Timestamp? clinicDateTs = clinicData['startDateTime'] as Timestamp?;

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

      await docRef.update({
        'status': 'accepted',
        'vitalsEntered': false,
        if (exactStartDateTime != null) 'startDateTime': Timestamp.fromDate(exactStartDateTime),
      });

      if (patientId.isNotEmpty) {
        final patientDoc = await _firestore.collection('patients').doc(patientId).get();
        if (patientDoc.exists) {
          final patientData = patientDoc.data()!;
          final phone = patientData['phoneNumber'] ?? '';
          final name = patientData['name'] ?? 'Patient';
          final referenceNumber = patientData['referenceNumber'] ?? '';

          await _firestore.collection('doctor_patient_history').add({
            'doctorId': doctorId,
            'patientId': patientId,
            'referenceNumber': referenceNumber,
            'department': clinicData['department'] ?? 'General',
            'appointmentDate': clinicData['startDateTime'],
            'slotStart': slotStart,
            'slotEnd': slotEnd,
            'acceptedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });

          if (phone.isNotEmpty) {
            smsSent = await _sendSms(phone: phone, message: "Hello $name, your appointment has been confirmed.");
          }
        }
      }
    } else if (action == 'reject') {
      await docRef.delete();
    }

    notifyListeners();
    return smsSent;
  }

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

  Future<void> endAppointment({
    required String clinicId,
    required String appointmentId,
    required String patientId,
    String? prescriptionText,
    File? prescriptionImageFile,
  }) async {
    try {
      String? prescriptionImageUrl;

      if (prescriptionImageFile != null) {
        debugPrint("Starting image upload to Storage...");
        final fileName = 'rx_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('prescriptions')
            .child(patientId)
            .child(fileName);

        final uploadTask = await storageRef.putFile(
          prescriptionImageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        ).timeout(const Duration(seconds: 30));

        prescriptionImageUrl = await uploadTask.ref.getDownloadURL();
        debugPrint("✅ Upload successful: $prescriptionImageUrl");
      }

      if (prescriptionText != null || prescriptionImageUrl != null) {
        debugPrint("Saving prescription to Firestore...");
        await _firestore
            .collection('patients')
            .doc(patientId)
            .collection('prescriptions')
            .add({
          'doctorId': doctorId,
          'createdAt': FieldValue.serverTimestamp(),
          'prescriptionText': prescriptionText,
          'prescriptionImageUrl': prescriptionImageUrl,
        });
        debugPrint("✅ Firestore record created.");
      }

      debugPrint("Deleting appointment slot...");
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
      debugPrint("❌ Error in endAppointment: $e");
      rethrow;
    }
  }

  Future<bool> _sendSms({required String phone, required String message}) async {
    final uri = Uri.parse('https://api.smsmobileapi.com/sendsms?apikey=$smsApiKey&recipients=${phone.replaceAll('+', '')}&message=${Uri.encodeComponent(message)}&sendsms=1');
    try {
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> getPatientReference(String patientId) async {
    if (patientRefs.containsKey(patientId)) return patientRefs[patientId]!;
    final doc = await _firestore.collection('patients').doc(patientId).get();
    if (doc.exists) {
      final ref = doc.data()?['referenceNumber'] ?? 'N/A';
      patientRefs[patientId] = ref;
      return ref;
    }
    return 'N/A';
  }
}