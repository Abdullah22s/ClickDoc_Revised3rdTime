import 'package:flutter/material.dart';

class DashboardItem {
  final String label;
  final IconData icon;

  DashboardItem({required this.label, required this.icon});
}

class DoctorDashboardViewModel extends ChangeNotifier {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  DoctorDashboardViewModel({
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  // Dashboard menu items
  final List<DashboardItem> _dashboardItems = [
    DashboardItem(label: 'Profile', icon: Icons.person),
    DashboardItem(label: 'Appointments', icon: Icons.calendar_today),
    DashboardItem(label: 'Physical OPD', icon: Icons.local_hospital),
    DashboardItem(label: 'Online Clinic', icon: Icons.medical_services),
  ];

  List<DashboardItem> get dashboardItems => _dashboardItems;
}
