import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor/doctor_physical_opd_model.dart';

class DoctorPhysicalOpdViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String doctorUid = '';
  String doctorName = '';
  String doctorQualification = '';

  final TextEditingController hospitalController = TextEditingController();
  bool loading = false;

  final List<String> departments = [
    'Cardiology',
    'Urology',
    'Neurology',
    'Orthopedics',
    'Dermatology',
    'Pediatrics',
    'General Medicine',
    'ENT',
    'Ophthalmology'
  ];

  String? selectedDepartment;

  final Map<String, bool> daysSelected = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  final Map<String, TimeOfDay?> fromTimes = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  final Map<String, TimeOfDay?> toTimes = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  DoctorPhysicalOpdViewModel() {
    _initDoctor();
  }

  Future<void> _initDoctor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    doctorUid = user.uid;

    final doc = await _firestore.collection('doctors').doc(doctorUid).get();
    if (doc.exists) {
      final data = doc.data()!;
      doctorName = data['name'] ?? 'Unknown';
      doctorQualification = data['qualification'] ?? '';
      notifyListeners();
    }
  }

  void toggleDay(String day, bool selected) {
    daysSelected[day] = selected;
    notifyListeners();
  }

  void setFromTime(String day, TimeOfDay time) {
    fromTimes[day] = time;
    notifyListeners();
  }

  void setToTime(String day, TimeOfDay time) {
    toTimes[day] = time;
    notifyListeners();
  }

  /// Convert TimeOfDay → "HH:mm"
  String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  /// ✅ PUBLIC STREAM FOR VIEW (MVVM Correct)
  Stream<QuerySnapshot> getOpdStream() {
    return _firestore
        .collection('doctors')
        .doc(doctorUid)
        .collection('physical_opds')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addOpd() async {
    final selectedDaysList =
    daysSelected.entries.where((e) => e.value).map((e) => e.key).toList();

    if (hospitalController.text.isEmpty ||
        selectedDaysList.isEmpty ||
        selectedDepartment == null) {
      return;
    }

    for (var day in selectedDaysList) {
      if (fromTimes[day] == null || toTimes[day] == null) return;
    }

    loading = true;
    notifyListeners();

    final opdCollection = _firestore
        .collection('doctors')
        .doc(doctorUid)
        .collection('physical_opds');

    for (var day in selectedDaysList) {
      await opdCollection.add({
        'hospitalName': hospitalController.text,
        'day': day,
        'fromTime': formatTime(fromTimes[day]!),
        'toTime': formatTime(toTimes[day]!),
        'department': selectedDepartment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    /// Reset form
    hospitalController.clear();
    for (var day in selectedDaysList) {
      daysSelected[day] = false;
      fromTimes[day] = null;
      toTimes[day] = null;
    }

    selectedDepartment = null;

    loading = false;
    notifyListeners();
  }

  Future<void> deleteOpd(String opdId) async {
    await _firestore
        .collection('doctors')
        .doc(doctorUid)
        .collection('physical_opds')
        .doc(opdId)
        .delete();

    notifyListeners();
  }
}
