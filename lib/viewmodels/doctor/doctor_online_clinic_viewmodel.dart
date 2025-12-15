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

  // Form fields
  String selectedDepartment = '';
  List<String> selectedDays = [];
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController feesController = TextEditingController();
  int appointmentDuration = 15;
  int bufferDuration = 15;

  final List<int> appointmentOptions = [10, 15, 20, 25, 30];
  final List<int> bufferOptions = [5, 10, 15, 20];

  bool isSaving = false;

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
      notifyListeners();
    }
  }

  // Toggle selected days
  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  // Format TimeOfDay without BuildContext (MVVM safe)
  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // Generate appointment slots
  List<AppointmentSlot> generateSlots() {
    if (startTime == null || endTime == null) return [];

    final start = DateTime(2024, 1, 1, startTime!.hour, startTime!.minute);
    final end = DateTime(2024, 1, 1, endTime!.hour, endTime!.minute);

    List<AppointmentSlot> slots = [];
    DateTime current = start;

    while (current.isBefore(end)) {
      final slotStart = current;
      final slotEnd = current.add(Duration(minutes: appointmentDuration));

      if (slotEnd.isAfter(end)) break;

      slots.add(
        AppointmentSlot(
          start: formatTime(TimeOfDay.fromDateTime(slotStart)),
          end: formatTime(TimeOfDay.fromDateTime(slotEnd)),
        ),
      );

      current = slotEnd.add(Duration(minutes: bufferDuration));
    }

    return slots;
  }

  Future<void> saveClinic() async {
    if (selectedDays.isEmpty ||
        startTime == null ||
        endTime == null ||
        feesController.text.isEmpty ||
        selectedDepartment.isEmpty) {
      return;
    }

    isSaving = true;
    notifyListeners();

    final slots = generateSlots();

    final clinicData = {
      'doctorName': doctorName,
      'qualification': doctorQualification,
      'department': selectedDepartment,
      'startTime': formatTime(startTime!),
      'endTime': formatTime(endTime!),
      'fees': int.tryParse(feesController.text) ?? 0,
      'appointmentDuration': appointmentDuration,
      'bufferDuration': bufferDuration,
      'slots': slots
          .map((s) => {'start': s.start, 'end': s.end})
          .toList(),
      'days': selectedDays,
      'type': 'online',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('doctors')
          .doc(doctorUid)
          .collection('online_clinics')
          .add(clinicData);

      // Reset form
      selectedDays = [];
      selectedDepartment = '';
      startTime = null;
      endTime = null;
      feesController.clear();
      appointmentDuration = 15;
      bufferDuration = 15;

    } catch (e) {
      debugPrint("Error saving clinic: $e");
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
