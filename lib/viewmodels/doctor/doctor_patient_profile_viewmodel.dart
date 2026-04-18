import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/patient/patient_model.dart';

class DoctorPatientProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  PatientModel? patient;
  bool isLoading = false;
  bool isUploading = false;
  String? _patientId;

  // =========================
  // FETCH PATIENT
  // =========================
  Future<void> fetchPatientByReferenceNumber(String referenceNumber) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await _firestore
          .collection('patients')
          .where('referenceNumber', isEqualTo: referenceNumber.trim())
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final doc = result.docs.first;
        _patientId = doc.id;
        patient = PatientModel.fromMap(doc.id, doc.data());
      } else {
        _patientId = null;
        patient = null;
      }
    } catch (e) {
      debugPrint("❌ fetch error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Stream<QuerySnapshot> getPrescriptionsStream() {
    if (_patientId == null) return const Stream.empty();
    return _firestore
        .collection('patients')
        .doc(_patientId)
        .collection('prescriptions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getReportsStream() {
    if (_patientId == null) return const Stream.empty();
    return _firestore
        .collection('patients')
        .doc(_patientId)
        .collection('reports')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("❌ open error: $e");
    }
  }

  Future<void> addTextPrescription(String text) async {
    if (_patientId == null || text.trim().isEmpty) return;
    await _firestore
        .collection('patients')
        .doc(_patientId)
        .collection('prescriptions')
        .add({
      'type': 'text',
      'content': text.trim(),
      'fileUrl': null,
      'fileName': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // FIXED UPLOAD LOGIC
  // =========================
  Future<void> pickAndUploadPrescriptionFile() async {
    if (_patientId == null) {
      debugPrint("❌ Cannot upload: Patient ID is null");
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Required for Web and safer for mobile
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

    isUploading = true;
    notifyListeners();

    try {
      // Reference to the specific folder structure
      final ref = _storage.ref().child('prescriptions/$_patientId/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        if (file.bytes == null) throw Exception("Web file bytes missing");
        uploadTask = ref.putData(file.bytes!, SettableMetadata(contentType: _getMimeType(fileName)));
      } else {
        // Use bytes for mobile as well if available, otherwise use path
        if (file.path != null) {
          uploadTask = ref.putFile(File(file.path!), SettableMetadata(contentType: _getMimeType(fileName)));
        } else if (file.bytes != null) {
          uploadTask = ref.putData(file.bytes!, SettableMetadata(contentType: _getMimeType(fileName)));
        } else {
          throw Exception("File data missing");
        }
      }

      // Track progress and completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      final isImage = fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg') ||
          fileName.toLowerCase().endsWith('.png');

      // Update Firestore only after storage is successful
      await _firestore
          .collection('patients')
          .doc(_patientId)
          .collection('prescriptions')
          .add({
        'type': isImage ? 'image' : 'pdf',
        'fileUrl': downloadUrl,
        'fileName': file.name,
        'content': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Upload successful: $downloadUrl");
    } catch (e) {
      debugPrint("❌ Upload error: $e");
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  String _getMimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> deletePrescriptionWithFile(String docId, String? fileUrl) async {
    if (_patientId == null) return;
    try {
      if (fileUrl != null && fileUrl.isNotEmpty) {
        await _storage.refFromURL(fileUrl).delete();
      }
      await _firestore
          .collection('patients')
          .doc(_patientId)
          .collection('prescriptions')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("❌ delete error: $e");
    }
  }

  String? get patientId => _patientId;
}