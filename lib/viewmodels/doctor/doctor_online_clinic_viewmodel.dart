import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';

class DoctorOnlineClinicViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String doctorUid = '';
  String doctorName = '';
  String doctorQualification = '';

  List<String> departments = [
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Pediatrics',
    'Orthopedics',
    'General Medicine',
    'Psychiatry',
    'Gynecology',
    'Dentistry'
  ];

  /// -------- FORM STATE --------
  String selectedDepartment = '';
  List<String> selectedDays = [];

  DateTime? selectedDate;
  int repeatWeeks = 1;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  TextEditingController feesController = TextEditingController();
  int appointmentDuration = 15;
  int bufferDuration = 15;

  final List<int> appointmentOptions = [10, 15, 20, 25, 30];
  final List<int> bufferOptions = [5, 10, 15, 20];

  bool isSaving = false;

  /// -------- UI DATA --------
  List<AppointmentSlot> previewSlots = [];
  List<Map<String, dynamic>> createdClinics = [];

  DoctorOnlineClinicViewModel() {
    _initDoctor();
  }

  Future<void> _initDoctor() async {
    final user = _auth.currentUser;
    if (user == null) return;

    doctorUid = user.uid;

    final doc = await _firestore.collection('doctors').doc(doctorUid).get();
    if (doc.exists) {
      final data = doc.data()!;
      doctorName = data['name'] ?? 'Unknown';
      doctorQualification = data['qualification'] ?? '';
    }

    await fetchCreatedClinics();
    notifyListeners();
  }

  /// -------- CALENDAR LOGIC --------
  void setSelectedDate(DateTime date) {
    selectedDate = date;

    /// Auto-select weekday
    final weekday = _weekdayFromDate(date);
    selectedDays = [weekday];

    notifyListeners();
  }

  void setRepeatWeeks(int value) {
    repeatWeeks = value;
    notifyListeners();
  }

  String _weekdayFromDate(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[d.weekday - 1];
  }

  List<DateTime> getGeneratedDates() {
    if (selectedDate == null) return [];
    return List.generate(
      repeatWeeks,
          (i) => selectedDate!.add(Duration(days: i * 7)),
    );
  }

  /// -------- FORM SETTERS --------
  void setDepartment(String value) {
    selectedDepartment = value;
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    startTime = time;
    _generateSlots();
  }

  void setEndTime(TimeOfDay time) {
    endTime = time;
    _generateSlots();
  }

  void setAppointmentDuration(int val) {
    appointmentDuration = val;
    _generateSlots();
  }

  void setBufferDuration(int val) {
    bufferDuration = val;
    _generateSlots();
  }

  /// -------- SLOT LOGIC (UNCHANGED CORE) --------
  String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  void _generateSlots() {
    previewSlots.clear();

    if (startTime == null || endTime == null) {
      notifyListeners();
      return;
    }

    final start = DateTime(2024, 1, 1, startTime!.hour, startTime!.minute);
    final end = DateTime(2024, 1, 1, endTime!.hour, endTime!.minute);

    DateTime current = start;

    while (current.isBefore(end)) {
      final slotEnd = current.add(Duration(minutes: appointmentDuration));
      if (slotEnd.isAfter(end)) break;

      previewSlots.add(
        AppointmentSlot(
          start: formatTime(TimeOfDay.fromDateTime(current)),
          end: formatTime(TimeOfDay.fromDateTime(slotEnd)),
        ),
      );

      current = slotEnd.add(Duration(minutes: bufferDuration));
    }

    notifyListeners();
  }

  /// -------- SAVE (FIXED) --------
  Future<void> saveClinic() async {
    if (selectedDays.isEmpty ||
        startTime == null ||
        endTime == null ||
        feesController.text.isEmpty ||
        selectedDepartment.isEmpty ||
        previewSlots.isEmpty) {
      debugPrint("❌ Validation failed");
      return;
    }

    isSaving = true;
    notifyListeners();

    try {
      await _firestore
          .collection('doctors')
          .doc(doctorUid)
          .collection('online_clinics')
          .add({
        'doctorName': doctorName,
        'qualification': doctorQualification,
        'department': selectedDepartment,
        'startTime': formatTime(startTime!),
        'endTime': formatTime(endTime!),
        'fees': int.parse(feesController.text),
        'appointmentDuration': appointmentDuration,
        'bufferDuration': bufferDuration,
        'slots': previewSlots
            .map((s) => {'start': s.start, 'end': s.end})
            .toList(),
        'days': selectedDays,
        'dates': getGeneratedDates()
            .map((d) => Timestamp.fromDate(d))
            .toList(),
        'type': 'online',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchCreatedClinics();
      _resetForm();

    } catch (e) {
      debugPrint("🔥 Firestore error: $e");
    }

    isSaving = false;
    notifyListeners();
  }

  /// -------- FETCH CREATED --------
  Future<void> fetchCreatedClinics() async {
    final snap = await _firestore
        .collection('doctors')
        .doc(doctorUid)
        .collection('online_clinics')
        .orderBy('createdAt', descending: true)
        .get();

    createdClinics = snap.docs.map((d) => d.data()).toList();
  }

  void _resetForm() {
    selectedDepartment = '';
    selectedDays.clear();
    selectedDate = null;
    startTime = null;
    endTime = null;
    feesController.clear();
    previewSlots.clear();
    repeatWeeks = 1;
  }
}
