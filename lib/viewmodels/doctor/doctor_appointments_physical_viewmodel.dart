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
    required String observationText,
    String? prescriptionText,
    File? prescriptionImageFile,
  }) async {
    final cleanObservation = observationText.trim();
    final cleanPrescription = prescriptionText?.trim() ?? '';

    if (cleanObservation.isEmpty) {
      throw Exception("Observation is required before ending appointment.");
    }

    final appointmentRef = _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .doc(clinicId)
        .collection('appointments')
        .doc(appointmentId);

    try {
      String? prescriptionImageUrl;

      if (prescriptionImageFile != null) {
        debugPrint("Starting physical prescription image upload...");
        final fileName = 'physical_rx_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        debugPrint("✅ Physical prescription upload successful: $prescriptionImageUrl");
      }

      final appointmentDoc = await appointmentRef.get();
      final appointmentData =
          appointmentDoc.data() as Map<String, dynamic>? ?? {};

      final clinicDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .doc(clinicId)
          .get();
      final clinicData = clinicDoc.data() ?? {};

      final patientDoc = await _firestore.collection('patients').doc(patientId).get();
      final patientData = patientDoc.data() ?? {};

      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final doctorData = doctorDoc.data() ?? {};

      final String doctorName = doctorData['name']?.toString() ?? 'Unknown Doctor';
      final String referenceNumber = patientData['referenceNumber']?.toString() ?? '';
      final now = FieldValue.serverTimestamp();
      final sourcePath = appointmentRef.path;

      final batch = _firestore.batch();

      // 1. Save physical observation permanently.
      final observationHistoryRef = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('physical_observations_history')
          .doc(appointmentId);

      batch.set(
        observationHistoryRef,
        {
          'doctorId': doctorId,
          'doctorName': doctorName,
          'patientId': patientId,
          'clinicId': clinicId,
          'appointmentId': appointmentId,
          'sourceAppointmentPath': sourcePath,
          'type': 'physical',
          'observation': cleanObservation,
          'prescriptionText': cleanPrescription,
          'prescriptionImageUrl': prescriptionImageUrl,
          'createdAt': now,
          'appointmentDate': appointmentData['startDateTime'] ??
              clinicData['startDateTime'] ??
              appointmentData['createdAt'] ??
              now,
        },
        SetOptions(merge: true),
      );

      // 2. Also merge observation into physical vitals history
      // so patient profile/history can show appointment notes with vitals later.
      final vitalsHistoryRef = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('physical_vitals_history')
          .doc(appointmentId);

      batch.set(
        vitalsHistoryRef,
        {
          'doctorId': doctorId,
          'doctorName': doctorName,
          'patientId': patientId,
          'clinicId': clinicId,
          'appointmentId': appointmentId,
          'sourceAppointmentPath': sourcePath,
          'type': 'physical',
          'observationSaved': true,
          'observation': cleanObservation,
          'prescriptionText': cleanPrescription,
          'prescriptionImageUrl': prescriptionImageUrl,
          'observationSavedAt': now,
        },
        SetOptions(merge: true),
      );

      // 3. Prescription is optional. Save it only if text or image exists.
      if (cleanPrescription.isNotEmpty || prescriptionImageUrl != null) {
        final prescriptionRef = _firestore
            .collection('patients')
            .doc(patientId)
            .collection('prescriptions')
            .doc('physical_$appointmentId');

        batch.set(
          prescriptionRef,
          {
            'doctorId': doctorId,
            'doctorName': doctorName,
            'patientId': patientId,
            'clinicId': clinicId,
            'appointmentId': appointmentId,
            'sourceAppointmentPath': sourcePath,
            'type': 'physical',
            'createdAt': now,
            'prescriptionText': cleanPrescription.isEmpty ? null : cleanPrescription,
            'prescriptionImageUrl': prescriptionImageUrl,
            'observation': cleanObservation,
          },
          SetOptions(merge: true),
        );
      }

      // 4. Update/create doctor-patient history record for later doctor-side history.
      final historySnapshot = await _firestore
          .collection('doctor_patient_history')
          .where('sourceAppointmentPath', isEqualTo: sourcePath)
          .limit(1)
          .get();

      final historyData = {
        'doctorId': doctorId,
        'patientId': patientId,
        'referenceNumber': referenceNumber,
        'department': clinicData['department'] ?? appointmentData['department'] ?? 'General',
        'appointmentDate': appointmentData['startDateTime'] ??
            clinicData['startDateTime'] ??
            appointmentData['createdAt'] ??
            now,
        'slotStart': appointmentData['start'],
        'slotEnd': appointmentData['end'],
        'status': 'completed',
        'type': 'physical',
        'clinicId': clinicId,
        'appointmentId': appointmentId,
        'sourceAppointmentPath': sourcePath,
        'observationSaved': true,
        'observation': cleanObservation,
        'prescriptionText': cleanPrescription,
        'prescriptionImageUrl': prescriptionImageUrl,
        'observationSavedAt': now,
      };

      if (historySnapshot.docs.isEmpty) {
        batch.set(
          _firestore.collection('doctor_patient_history').doc('physical_$appointmentId'),
          {
            ...historyData,
            'acceptedAt': appointmentData['acceptedAt'] ?? now,
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          historySnapshot.docs.first.reference,
          historyData,
          SetOptions(merge: true),
        );
      }

      // 5. End appointment by removing it from active physical appointments.
      batch.delete(appointmentRef);

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error in physical endAppointment: $e");
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
}