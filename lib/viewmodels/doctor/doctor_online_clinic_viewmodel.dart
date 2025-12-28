import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorOnlineClinicViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = true;
  bool isSaving = false;

  String doctorId = '';
  String doctorName = '';
  String doctorQualification = '';

  DateTime? selectedDate;
  List<String> selectedDays = [];
  int repeatWeeks = 1;

  final List<String> departments = [
    'Cardiology','Neurology','Dermatology','Orthopedics','Pediatrics',
    'General Medicine','ENT','Psychiatry',
  ];
  String selectedDepartment = '';

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final TextEditingController feesController = TextEditingController();

  int appointmentDuration = 15;
  int bufferDuration = 5;
  final List<int> appointmentOptions = [10, 15, 20, 30];
  final List<int> bufferOptions = [0, 5, 10, 15];

  List<Map<String, String>> previewSlots = [];
  List<Map<String, dynamic>> createdClinics = [];

  DoctorOnlineClinicViewModel() {
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
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
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
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

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
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}';
  }

  Future<void> saveClinic() async {
    if (selectedDate == null ||
        selectedDepartment.isEmpty ||
        startTime == null ||
        endTime == null ||
        feesController.text.isEmpty) return;

    isSaving = true;
    notifyListeners();

    _generatePreviewSlots();

    try {
      final startDateTime = DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day,
          startTime!.hour, startTime!.minute
      );
      final endDateTime = DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day,
          endTime!.hour, endTime!.minute
      );

      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .add({
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

      // Reset form
      feesController.clear();
      selectedDate = null;
      selectedDepartment = '';
      startTime = null;
      endTime = null;
      previewSlots.clear();

      await _loadCreatedClinics();
    } catch (e) {
      print("Error saving clinic: $e");
    }

    isSaving = false;
    notifyListeners();
  }

  Future<void> _loadCreatedClinics() async {
    final snap = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('online_clinics')
        .orderBy('createdAt', descending: true)
        .get();

    final now = DateTime.now();
    // Delete past clinics automatically
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
        .collection('online_clinics')
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
      return List<Map<String, String>>.from(clinic['slots']);
    }

    // Fallback slot generation
    final startParts = (clinic['startTime'] as String).split(":").map(int.parse).toList();
    final endParts = (clinic['endTime'] as String).split(":").map(int.parse).toList();
    final appDur = (clinic['appointmentDuration'] as num).toInt();
    final bufDur = (clinic['bufferDuration'] as num).toInt();

    int startMins = startParts[0] * 60 + startParts[1];
    int endMins = endParts[0] * 60 + endParts[1];

    List<Map<String,String>> slots = [];
    while (startMins + appDur <= endMins) {
      final endSlot = startMins + appDur;
      slots.add({
        'start':'${(startMins~/60).toString().padLeft(2,'0')}:${(startMins%60).toString().padLeft(2,'0')}',
        'end':'${(endSlot~/60).toString().padLeft(2,'0')}:${(endSlot%60).toString().padLeft(2,'0')}'
      });
      startMins = endSlot + bufDur;
    }
    return slots;
  }

  @override
  void dispose() {
    feesController.dispose();
    super.dispose();
  }
}
