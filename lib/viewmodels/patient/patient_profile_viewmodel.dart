import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/patient/patient_profile_model.dart';

class PatientProfileViewModel extends ChangeNotifier {
  final String userEmail;

  PatientProfileModel? patient;
  bool loading = true;

  String? _patientId;

  PatientProfileViewModel({required this.userEmail}) {
    _init();
  }

  /// =========================
  /// INIT (LOAD + ID ONCE)
  /// =========================
  Future<void> _init() async {
    await _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;

        _patientId = doc.id;
        patient = PatientProfileModel.fromMap(doc.data());
      }
    } catch (e) {
      debugPrint("Error fetching patient info: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// =========================
  /// UPLOAD REPORT (FIXED + SAFE)
  /// =========================
  Future<void> uploadReport() async {
    try {
      if (_patientId == null) {
        debugPrint("Patient ID not loaded yet");
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      final isPdf = fileName.toLowerCase().endsWith('.pdf');

      final ref = FirebaseStorage.instance
          .ref()
          .child('patient_reports/$_patientId/$fileName');

      /// ✅ FIX: add metadata (prevents your crash)
      final task = ref.putFile(
        file,
        SettableMetadata(
          contentType: isPdf ? 'application/pdf' : 'image/jpeg',
        ),
      );

      await task;

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(_patientId)
          .collection('reports')
          .add({
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'fileType': isPdf ? 'pdf' : 'image',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  /// =========================
  /// STREAM REPORTS (FIXED)
  /// =========================
  Stream<QuerySnapshot> getReportsStream() {
    if (_patientId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// OPEN REPORT
  /// =========================
  Future<void> openReport(String url) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint("Could not launch URL");
      }
    } catch (e) {
      debugPrint("Open report error: $e");
    }
  }
}