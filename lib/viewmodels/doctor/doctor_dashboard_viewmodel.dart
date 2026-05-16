import 'package:flutter/material.dart';
import '../../models/doctor/doctor_dashboard_model.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  DoctorDashboardViewModel({
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  List<DoctorDashboardModel> get dashboardItems => [
    DoctorDashboardModel(icon: Icons.person, label: 'Profile'),
    DoctorDashboardModel(icon: Icons.videocam_rounded, label: 'Online Appointments'),
    DoctorDashboardModel(icon: Icons.assignment_ind_rounded, label: 'Physical Requests'),
    DoctorDashboardModel(icon: Icons.local_hospital_rounded, label: 'Physical OPD'),
    DoctorDashboardModel(icon: Icons.medical_services_rounded, label: 'Online Clinic'),
    DoctorDashboardModel(icon: Icons.people_alt_rounded, label: 'Current Patients'),
  ];
}