class DoctorOnlineClinicModel {
  final String id;
  final String doctorId;
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
    required this.doctorId,
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

// ✅ NEW MODEL FOR PHYSICAL CLINICS
class PhysicalClinicModel {
  final String id;
  final String hospitalName;
  final String startTime;
  final String endTime;
  final List<String> days;
  final List<AppointmentSlot> slots;
  final int fees;

  PhysicalClinicModel({
    required this.id,
    required this.hospitalName,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.slots,
    required this.fees,
  });

  factory PhysicalClinicModel.fromMap(String id, Map<String, dynamic> data) {
    return PhysicalClinicModel(
      id: id,
      hospitalName: data['hospitalName'] ?? 'Unknown Hospital',
      startTime: data['startTime'] ?? '--:--',
      endTime: data['endTime'] ?? '--:--',
      days: List<String>.from(data['days'] ?? []),
      fees: (data['fees'] as num? ?? 0).toInt(),
      slots: (data['slots'] as List? ?? [])
          .map((s) => AppointmentSlot(
        start: s['start'] ?? '',
        end: s['end'] ?? '',
      ))
          .toList(),
    );
  }
}

class AppointmentSlot {
  final String start;
  final String end;

  AppointmentSlot({required this.start, required this.end});
}