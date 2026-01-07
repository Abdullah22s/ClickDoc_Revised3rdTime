class DoctorSearchResult {
  final String doctorId;
  final String doctorName;
  final bool hasOnline;
  final bool hasPhysical;

  DoctorSearchResult({
    required this.doctorId,
    required this.doctorName,
    required this.hasOnline,
    required this.hasPhysical,
  });
}
