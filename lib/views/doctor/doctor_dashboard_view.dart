import 'package:flutter/material.dart';
import '../../viewmodels/doctor/doctor_dashboard_viewmodel.dart';
import 'doctor_profile_view.dart';
import 'doctor_physical_opd_view.dart';
import 'doctor_online_clinic_view.dart';
import 'doctor_appointments_view.dart'; // Online appointments
import 'doctor_appointments_physical_view.dart'; // Physical requests
import 'doctor_current_patients_view.dart';

class DoctorDashboardScreen extends StatelessWidget {
  final DoctorDashboardViewModel viewModel;

  const DoctorDashboardScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final dashboardItems = viewModel.dashboardItems
        .where((item) => !item.label.toLowerCase().contains('medical info'))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHeader(context),
                const SizedBox(height: 40),
                const Text(
                  "Overview",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernGrid(context, dashboardItems),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3B82F6), width: 2.0),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage: viewModel.userPhotoUrl != null
                ? NetworkImage(viewModel.userPhotoUrl!)
                : const AssetImage('assets/default_user.png') as ImageProvider,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Good to see you,",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Dr. ${viewModel.userName}",
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
          ),
        ),
      ],
    );
  }

  Widget _buildModernGrid(BuildContext context, List<dynamic> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) => _buildPremiumCard(context, items[index]),
        );
      },
    );
  }

  Widget _buildPremiumCard(BuildContext context, dynamic item) {
    final theme = _getThemeFor(item.label);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _navigate(context, item.label),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 28, color: theme.primaryColor),
            ),
            const Spacer(),
            Text(
              item.label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getSubtitleFor(item.label),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CardTheme _getThemeFor(String label) {
    switch (label) {
      case 'Profile':
        return _CardTheme(
          primaryColor: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
          shadowColor: const Color(0xFF3B82F6).withOpacity(0.1),
        );
      case 'Online Appointments':
        return _CardTheme(
          primaryColor: const Color(0xFFF97316),
          bgColor: const Color(0xFFFFF7ED),
          shadowColor: const Color(0xFFF97316).withOpacity(0.15),
        );
      case 'Physical Requests':
        return _CardTheme(
          primaryColor: const Color(0xFF14B8A6),
          bgColor: const Color(0xFFF0FDFA),
          shadowColor: const Color(0xFF14B8A6).withOpacity(0.15),
        );
      case 'Physical OPD':
        return _CardTheme(
          primaryColor: const Color(0xFF0EA5E9),
          bgColor: const Color(0xFFF0F9FF),
          shadowColor: const Color(0xFF0EA5E9).withOpacity(0.1),
        );
      case 'Online Clinic':
        return _CardTheme(
          primaryColor: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
          shadowColor: const Color(0xFF10B981).withOpacity(0.1),
        );
      case 'Current Patients':
        return _CardTheme(
          primaryColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.1),
        );
      default:
        return _CardTheme(
          primaryColor: const Color(0xFF64748B),
          bgColor: const Color(0xFFF1F5F9),
          shadowColor: Colors.black.withOpacity(0.05),
        );
    }
  }

  String _getSubtitleFor(String label) {
    switch (label) {
      case 'Profile': return 'Manage account';
      case 'Online Appointments': return 'Video consults';
      case 'Physical Requests': return 'Clinic requests';
      case 'Physical OPD': return 'Visit setup';
      case 'Online Clinic': return 'Session setup';
      case 'Current Patients': return 'Active cases';
      default: return 'Quick access';
    }
  }

  void _navigate(BuildContext context, String label) {
    final Map<String, Widget> routes = {
      'Profile': DoctorProfileScreen(userEmail: viewModel.userEmail),
      'Online Appointments': DoctorAppointmentsScreen(),
      'Physical Requests': const DoctorPhysicalAppointmentsScreen(),
      'Physical OPD': const DoctorPhysicalOpdView(),
      'Online Clinic': const DoctorOnlineClinicScreen(),
      'Current Patients': const DoctorCurrentPatientsView(),
    };

    if (routes.containsKey(label)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => routes[label]!));
    }
  }
}

class _CardTheme {
  final Color primaryColor, bgColor, shadowColor;
  _CardTheme({required this.primaryColor, required this.bgColor, required this.shadowColor});
}