import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorPhysicalOpdViewmodel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = true;
  bool isSaving = false;

  String doctorId = '';
  String doctorName = '';
  String doctorQualification = '';

  DateTime? selectedDate;
  List<String> selectedDays = [];

  final List<String> departments = [
    'Cardiology', 'Neurology', 'Dermatology', 'Orthopedics', 'Pediatrics',
    'General Physician', 'ENT', 'Psychiatry',
  ];
  String selectedDepartment = '';

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // New Controllers for Physical Location
  final TextEditingController feesController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  int appointmentDuration = 15;
  int bufferDuration = 5;
  final List<int> appointmentOptions = [10, 15, 20, 30];
  final List<int> bufferOptions = [0, 5, 10, 15];

  List<Map<String, String>> previewSlots = [];
  List<Map<String, dynamic>> createdClinics = [];

  DoctorPhysicalOpdViewmodel() {
    _init();
  }

  Future<void> _init() async {
    final user = _auth.currentUser;
    if (user == null) return;

    doctorId = user.uid;
    final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();

    if (doctorDoc.exists) {
      final data = doctorDoc.data()!;
      doctorName = data['name'] ?? '';
      doctorQualification = (data['qualifications'] is List && data['qualifications'].isNotEmpty)
          ? data['qualifications'].join(', ')
          : '';
    }

    await _loadCreatedClinics();
    loading = false;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    selectedDays = [_weekdayName(date.weekday)];
    notifyListeners();
  }

  String _weekdayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  void setDepartment(String value) {
    selectedDepartment = value;
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    startTime = time;
    _generatePreviewSlots();
    notifyListeners();
  }

  void setEndTime(TimeOfDay time) {
    endTime = time;
    _generatePreviewSlots();
    notifyListeners();
  }

  void setAppointmentDuration(int v) {
    appointmentDuration = v;
    _generatePreviewSlots();
    notifyListeners();
  }

  void setBufferDuration(int v) {
    bufferDuration = v;
    _generatePreviewSlots();
    notifyListeners();
  }

  String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _generatePreviewSlots() {
    previewSlots.clear();
    if (startTime == null || endTime == null) return;

    int startMinutes = startTime!.hour * 60 + startTime!.minute;
    int endMinutes = endTime!.hour * 60 + endTime!.minute;

    while (startMinutes + appointmentDuration <= endMinutes) {
      final endSlot = startMinutes + appointmentDuration;
      previewSlots.add({
        'start': _minToTime(startMinutes),
        'end': _minToTime(endSlot)
      });
      startMinutes = endSlot + bufferDuration;
    }
  }

  String _minToTime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<String?> saveClinic() async {
    if (selectedDate == null ||
        selectedDepartment.isEmpty ||
        startTime == null ||
        endTime == null ||
        hospitalController.text.isEmpty ||
        cityController.text.isEmpty ||
        feesController.text.isEmpty) {
      return "Please fill all fields.";
    }

    isSaving = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      final startDateTime = DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day,
          startTime!.hour, startTime!.minute
      );
      final endDateTime = DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day,
          endTime!.hour, endTime!.minute
      );

      if (startDateTime.isBefore(now)) {
        isSaving = false;
        notifyListeners();
        return "Cannot create an OPD for a time that has already passed.";
      }

      if (endDateTime.isBefore(startDateTime)) {
        isSaving = false;
        notifyListeners();
        return "End time cannot be before start time.";
      }

      final querySnapshot = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final existingStart = (data['startDateTime'] as Timestamp).toDate();
        final existingEnd = (data['endDateTime'] as Timestamp).toDate();

        if (startDateTime.isBefore(existingEnd) && endDateTime.isAfter(existingStart)) {
          isSaving = false;
          notifyListeners();
          return "Slot overlaps with an existing OPD on this day.";
        }
      }

      _generatePreviewSlots();

      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .add({
        'hospitalName': hospitalController.text.trim(),
        'city': cityController.text.trim(),
        'department': selectedDepartment,
        'doctorId': doctorId,
        'days': selectedDays,
        'startTime': formatTime(startTime!),
        'endTime': formatTime(endTime!),
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
        'fees': int.tryParse(feesController.text) ?? 0,
        'appointmentDuration': appointmentDuration,
        'bufferDuration': bufferDuration,
        'slots': previewSlots,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear all fields
      feesController.clear();
      hospitalController.clear();
      cityController.clear();
      selectedDate = null;
      selectedDepartment = '';
      startTime = null;
      endTime = null;
      previewSlots.clear();

      await _loadCreatedClinics();
      isSaving = false;
      notifyListeners();
      return null;
    } catch (e) {
      isSaving = false;
      notifyListeners();
      return "Error: $e";
    }
  }

  Future<void> _loadCreatedClinics() async {
    final snap = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .orderBy('createdAt', descending: true)
        .get();

    final now = DateTime.now();
    for (var doc in snap.docs) {
      final data = doc.data();
      if (data.containsKey('endDateTime')) {
        final endDateTime = (data['endDateTime'] as Timestamp).toDate();
        if (endDateTime.isBefore(now)) {
          await doc.reference.delete();
        }
      }
    }

    final updatedSnap = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .orderBy('createdAt', descending: true)
        .get();

    createdClinics = updatedSnap.docs.map((e) {
      final data = e.data();
      data['appointmentDuration'] = (data['appointmentDuration'] as num).toInt();
      data['bufferDuration'] = (data['bufferDuration'] as num).toInt();
      return data;
    }).toList();

    notifyListeners();
  }

  List<Map<String, String>> getClinicSlots(Map<String, dynamic> clinic) {
    if (clinic.containsKey('slots') && (clinic['slots'] as List).isNotEmpty) {
      return (clinic['slots'] as List).map((slot) {
        return {
          'start': slot['start'].toString(),
          'end': slot['end'].toString(),
        };
      }).toList();
    }
    return [];
  }

  @override
  void dispose() {
    feesController.dispose();
    hospitalController.dispose();
    cityController.dispose();
    super.dispose();
  }
}