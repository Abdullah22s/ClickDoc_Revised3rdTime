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

  DoctorAppointment({
    required this.id,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.fees,
    required this.appointmentDuration,
    required this.bufferDuration,
    required this.slots,
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
    );
  }
}
