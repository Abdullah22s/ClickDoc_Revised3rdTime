class DoctorOnlineClinicModel {
  final String id;
  final String doctorName;
  final String doctorQualification;
  final String department;
  final String startTime;
  final String endTime;
  final int fees;
  final int appointmentDuration;
  final int bufferDuration;
  final List<String> days;
  final List<AppointmentSlot> slots;

  DoctorOnlineClinicModel({
    required this.id,
    required this.doctorName,
    required this.doctorQualification,
    required this.department,
    required this.startTime,
    required this.endTime,
    required this.fees,
    required this.appointmentDuration,
    required this.bufferDuration,
    required this.days,
    required this.slots,
  });
}

class AppointmentSlot {
  final String start;
  final String end;

  AppointmentSlot({required this.start, required this.end});
}
