import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for kIsWeb check
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
  bool isUploading = false; // Added to track upload state

  String? _patientId;

  PatientProfileViewModel({required this.userEmail}) {
    _init();
  }

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
  /// STREAM PRESCRIPTIONS (NEW)
  /// =========================
  Stream<QuerySnapshot> getPrescriptionsStream() {
    if (_patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('prescriptions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// STREAM REPORTS
  /// =========================
  Stream<QuerySnapshot> getReportsStream() {
    if (_patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// =========================
  /// UPLOAD REPORT
  /// =========================
  Future<void> uploadReport() async {
    if (_patientId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: kIsWeb, // Important for web support
      );

      if (result == null) return;

      isUploading = true;
      notifyListeners();

      final file = result.files.single;
      final fileName = file.name;
      final isPdf = fileName.toLowerCase().endsWith('.pdf');

      final ref = FirebaseStorage.instance
          .ref()
          .child('patient_reports/$_patientId/$fileName');

      // Handle both Web and Mobile
      if (kIsWeb) {
        await ref.putData(file.bytes!, SettableMetadata(contentType: isPdf ? 'application/pdf' : 'image/jpeg'));
      } else {
        await ref.putFile(File(file.path!), SettableMetadata(contentType: isPdf ? 'application/pdf' : 'image/jpeg'));
      }

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

    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> openReport(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Open error: $e");
    }
  }

  String? get patientId => _patientId;
}