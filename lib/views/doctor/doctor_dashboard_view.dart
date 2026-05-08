import 'package:flutter/material.dart';
import '../../viewmodels/doctor/doctor_dashboard_viewmodel.dart';
import 'doctor_profile_view.dart';
import 'doctor_physical_opd_view.dart';
import 'doctor_online_clinic_view.dart';
import 'doctor_appointments_view.dart';
import 'doctor_current_patients_view.dart';

class DoctorDashboardScreen extends StatelessWidget {
  final DoctorDashboardViewModel viewModel;

  const DoctorDashboardScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // 🔥 Dynamically filter out 'Medical Info'
    final dashboardItems = viewModel.dashboardItems
        .where((item) => !item.label.toLowerCase().contains('medical info'))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warmer, softer background
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
                    color: Color(0xFF1E293B), // Slate 800
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

  /// 🩺 Friendly profile header (Updated to handle logout at the UI level)
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
            tooltip: 'Logout',
            onPressed: () {
              // 🔥 FIXED: Handled directly in the view instead of calling the ViewModel
              // Add your authentication sign-out logic here if needed (e.g., FirebaseAuth.instance.signOut())

              // This clears the navigation stack and returns to your login/auth screen
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ),
      ],
    );
  }

  /// 📊 Redesigned Friendly Grid
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
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildPremiumCard(context, item);
          },
        );
      },
    );
  }

  /// Extracted Card Widget with Dynamic Colored Glows
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
              child: Icon(
                item.icon,
                size: 28,
                color: theme.primaryColor,
              ),
            ),
            const Spacer(),
            Text(
              item.label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getSubtitleFor(item.label),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to assign distinct, friendly colors and glowing shadows to each tile
  _CardTheme _getThemeFor(String label) {
    switch (label) {
      case 'Profile':
        return _CardTheme(
          primaryColor: const Color(0xFF3B82F6), // Blue
          bgColor: const Color(0xFFEFF6FF),
          shadowColor: const Color(0xFF3B82F6).withOpacity(0.2),
        );
      case 'Appointments':
        return _CardTheme(
          primaryColor: const Color(0xFFF97316), // Orange
          bgColor: const Color(0xFFFFF7ED),
          shadowColor: const Color(0xFFF97316).withOpacity(0.2),
        );
      case 'Physical OPD':
        return _CardTheme(
          primaryColor: const Color(0xFF14B8A6), // Teal
          bgColor: const Color(0xFFF0FDFA),
          shadowColor: const Color(0xFF14B8A6).withOpacity(0.2),
        );
      case 'Online Clinic':
        return _CardTheme(
          primaryColor: const Color(0xFF10B981), // Emerald
          bgColor: const Color(0xFFECFDF5),
          shadowColor: const Color(0xFF10B981).withOpacity(0.2),
        );
      case 'Current Patients':
        return _CardTheme(
          primaryColor: const Color(0xFF8B5CF6), // Purple
          bgColor: const Color(0xFFF5F3FF),
          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.2),
        );
      default:
        return _CardTheme(
          primaryColor: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
          shadowColor: const Color(0xFF3B82F6).withOpacity(0.2),
        );
    }
  }

  String _getSubtitleFor(String label) {
    switch (label) {
      case 'Profile':
        return 'Manage account';
      case 'Appointments':
        return 'View schedule';
      case 'Physical OPD':
        return 'Clinic visits';
      case 'Online Clinic':
        return 'Video consults';
      case 'Current Patients':
        return 'Active cases';
      default:
        return 'Quick access';
    }
  }

  void _navigate(BuildContext context, String label) {
    if (label == 'Profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorProfileScreen(userEmail: viewModel.userEmail),
        ),
      );
    } else if (label == 'Appointments') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen()),
      );
    } else if (label == 'Physical OPD') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorPhysicalOpdScreen()),
      );
    } else if (label == 'Online Clinic') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorOnlineClinicScreen()),
      );
    } else if (label == 'Current Patients') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorCurrentPatientsView()),
      );
    }
  }
}

/// Simple model for card coloring
class _CardTheme {
  final Color primaryColor;
  final Color bgColor;
  final Color shadowColor;

  _CardTheme({
    required this.primaryColor,
    required this.bgColor,
    required this.shadowColor,
  });
}