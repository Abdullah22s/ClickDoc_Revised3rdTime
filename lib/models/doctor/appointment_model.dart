import 'package:cloud_firestore/cloud_firestore.dart';
class AppointmentSlot {
  final String start;
  final String end;

  AppointmentSlot({required this.start, required this.end});

  factory AppointmentSlot.fromMap(Map<String, dynamic> map) {
    return AppointmentSlot(
      start: map['start'] ?? '',
      end: map['end'] ?? '',
    );
  }
}

class DoctorAppointment {
  final String id;
  final List<String> days;
  final String startTime;
  final String endTime;
  final int fees;
  final int appointmentDuration;
  final int bufferDuration;
  final List<AppointmentSlot> slots;

  // 🔹 New fields for automatic deletion
  final DateTime startDateTime;
  final DateTime endDateTime;

  DoctorAppointment({
    required this.id,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.fees,
    required this.appointmentDuration,
    required this.bufferDuration,
    required this.slots,
    required this.startDateTime,
    required this.endDateTime,
  });

  factory DoctorAppointment.fromMap(String id, Map<String, dynamic> map) {
    final slotList = <AppointmentSlot>[];
    if (map['slots'] != null) {
      for (var slot in map['slots']) {
        slotList.add(AppointmentSlot.fromMap(Map<String, dynamic>.from(slot)));
      }
    }

    return DoctorAppointment(
      id: id,
      days: List<String>.from(map['days'] ?? []),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      fees: map['fees'] ?? 0,
      appointmentDuration: map['appointmentDuration'] ?? 0,
      bufferDuration: map['bufferDuration'] ?? 0,
      slots: slotList,
      // 🔹 Parse startDateTime and endDateTime from Firestore Timestamp
      startDateTime: map['startDateTime'] != null
          ? (map['startDateTime'] as Timestamp).toDate()
          : DateTime.now(),
      endDateTime: map['endDateTime'] != null
          ? (map['endDateTime'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
