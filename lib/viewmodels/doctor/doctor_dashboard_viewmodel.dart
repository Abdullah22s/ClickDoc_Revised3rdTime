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
    DoctorDashboardModel(icon: Icons.calendar_today, label: 'Appointments'),
    DoctorDashboardModel(icon: Icons.local_hospital, label: 'Physical OPD'),
    DoctorDashboardModel(icon: Icons.medical_services, label: 'Online Clinic'),
  ];
}
