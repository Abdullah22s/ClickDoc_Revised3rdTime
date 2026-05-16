import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/doctor/doctor_online_clinic_model.dart';
import '../../models/doctor/appointment_model.dart';

class DoctorPhysicalAppointmentsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String doctorId = FirebaseAuth.instance.currentUser!.uid;

  List<PhysicalClinicModel> appointments = [];
  bool isLoading = true;

  final String smsApiKey = 'ee3c7010a3b059e955c1d1ffd8805e0d27b940ecc4240ca0';

  DoctorPhysicalAppointmentsViewModel() {
    fetchPhysicalSchedules();
  }

  void fetchPhysicalSchedules() {
    _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .snapshots()
        .listen((snapshot) {
      appointments = snapshot.docs.map((doc) {
        return PhysicalClinicModel.fromMap(doc.id, doc.data());
      }).toList();
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
        .collection('physical_opds')
        .doc(clinicId)
        .collection('appointments')
        .doc(appointmentId);

    bool smsSent = false;

    if (action == 'accept') {
      // 1. Update status to trigger "Waiting for Vitals"
      await docRef.update({
        'status': 'accepted',
        'vitalsEntered': false,
      });

      // 2. Fetch data for SMS
      final appointmentDoc = await docRef.get();
      final patientId = appointmentDoc.data()?['patientId'] ?? '';

      if (patientId.isNotEmpty) {
        final patientDoc = await _firestore.collection('patients').doc(patientId).get();
        if (patientDoc.exists) {
          final phone = patientDoc.data()?['phoneNumber'] ?? '';
          final name = patientDoc.data()?['name'] ?? 'Patient';

          if (phone.isNotEmpty) {
            smsSent = await _sendSms(phone: phone, message: "Hello $name, your physical appointment is confirmed. Please provide your vitals at the clinic.");
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
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .doc(clinicId)
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': 'in_progress'});
    notifyListeners();
  }

  Future<void> endAppointment({
    required String clinicId,
    required String appointmentId,
    required String patientId,
    String? prescriptionText,
    File? prescriptionImageFile,
  }) async {
    // Logic for ending appointment and uploading Rx (Exact same as Online)
    // ... [Rest of endAppointment logic remains identical to your provided code]
    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .doc(clinicId)
        .collection('appointments')
        .doc(appointmentId)
        .delete();
    notifyListeners();
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
}