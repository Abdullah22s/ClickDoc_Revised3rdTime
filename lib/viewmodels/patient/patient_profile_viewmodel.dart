import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

// Ensure this path correctly points to where your PatientFormModel is
import '../../models/patient/patient_form_model.dart';

class PatientProfileViewModel extends ChangeNotifier {
  final String userEmail;

  // Fixed: Changed type to PatientFormModel
  PatientFormModel? patient;
  bool loading = true;
  bool isUploading = false;
  String? _patientId;

  final List<String> reportCategories = [
    'Blood Report',
    'Diabetic Report',
    'Radiology (X-Ray/MRI)',
    'Prescription',
    'Other'
  ];

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
        final data = doc.data();

        // Manual mapping to PatientFormModel to ensure type safety
        patient = PatientFormModel(
          referenceNumber: data['referenceNumber']?.toString() ?? '',
          name: data['name']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          phoneNumber: data['phoneNumber']?.toString() ?? '',
          age: data['age']?.toString() ?? '',
          weight: data['weight']?.toString() ?? '',
          gender: data['gender']?.toString() ?? '',
          bloodGroup: data['bloodGroup']?.toString() ?? '',
          medicalHistory: List<String>.from(data['medicalHistory'] ?? []),
        );
      }
    } catch (e) {
      debugPrint("Error fetching patient info: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> getReportsStream() {
    if (_patientId == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> uploadReport(String category) async {
    if (_patientId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: kIsWeb,
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
        'category': category,
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