import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/patient/patient_dashboard_viewmodel.dart';
import '../../views/patient/patient_profile_view.dart';
import '../../views/patient/patient_physical_opd_view.dart';
import '../../views/patient/patient_online_doctors_view.dart';
import '../../views/patient/search_doctor_by_symptom_view.dart';
import '../../views/patient/patient_prescriptions_view.dart';
// ✅ NEW IMPORT ADDED
import '../../views/patient/patient_upcoming_appointments_view.dart';

class PatientDashboardScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const PatientDashboardScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientDashboardViewModel(
        userName: userName,
        userEmail: userEmail,
        userPhotoUrl: userPhotoUrl,
      ),
      child: Consumer<PatientDashboardViewModel>(
        builder: (context, vm, _) {
          /// 🚑 SAFE INIT HOOK (PRESERVED)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!vm.isLoading && vm.patientData != null) {
              // Future-safe place if you want auto tracking restore later
            }
          });

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC), // Warmer, softer background
            body: Stack(
              children: [
                SafeArea(
                  child: vm.isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6), // Friendly blue
                    ),
                  )
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 👤 FRIENDLY USER HEADER
                          _buildModernHeader(context, vm),

                          const SizedBox(height: 30),

                          /// 🔴 PREMIUM EMERGENCY SOS BUTTON
                          _buildEmergencyButton(context, vm),

                          const SizedBox(height: 32),

                          const Text(
                            "Our Services",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// 📦 GLOWING FEATURES GRID
                          _buildServicesGrid(context),

                          const SizedBox(height: 32),

                          /// 🧾 FRIENDLY MEDICAL INFO CARD
                          if (vm.patientData != null) ...[
                            const Text(
                              "Your Medical Profile",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildMedicalSummaryCard(vm.patientData!),
                            const SizedBox(height: 30),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),

                /// 🔴 SOS LOADING OVERLAY (PRESERVED)
                if (vm.sosLoading)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.redAccent),
                          SizedBox(height: 24),
                          Text(
                            "Sending Emergency SOS...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Recording audio & finding nearby ambulances",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 HEADER
  Widget _buildModernHeader(BuildContext context, PatientDashboardViewModel vm) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3B82F6), width: 2.5), // Friendly blue ring
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: userPhotoUrl != null
                ? NetworkImage(userPhotoUrl!)
                : const AssetImage('assets/images/default_avatar.png')
            as ImageProvider,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Good to see you,",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
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
                color: const Color(0xFFEF4444).withOpacity(0.15), // Soft red glow for logout
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Logout',
            onPressed: () => vm.signOut(context),
          ),
        ),
      ],
    );
  }

  /// 🔹 EMERGENCY BUTTON
  Widget _buildEmergencyButton(BuildContext context, PatientDashboardViewModel vm) {
    return GestureDetector(
      onTap: vm.sosLoading ? null : () async => await vm.sendEmergencySOS(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.4), // Vibrant red shadow
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Text(
              "EMERGENCY SOS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 REDESIGNED GLOWING GRID
  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.95,
      children: [
        // ✅ NEW: UPCOMING ONLINE APPOINTMENTS
        _buildPremiumCard(
          context: context,
          icon: Icons.online_prediction_rounded,
          label: "Upcoming Online",
          subtitle: "Enter vitals",
          iconColor: const Color(0xFFF97316), // Orange
          bgColor: const Color(0xFFFFF7ED),
          shadowColor: const Color(0xFFF97316).withOpacity(0.2),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientUpcomingAppointmentsView()),
          ),
        ),
        _buildPremiumCard(
          context: context,
          icon: Icons.person_outline,
          label: "My Profile",
          subtitle: "Manage account",
          iconColor: const Color(0xFF3B82F6), // Blue
          bgColor: const Color(0xFFEFF6FF),
          shadowColor: const Color(0xFF3B82F6).withOpacity(0.2), // Blue Glow
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PatientProfileView(userEmail: userEmail)),
          ),
        ),
        _buildPremiumCard(
          context: context,
          icon: Icons.local_hospital_outlined,
          label: "Physical OPDs",
          subtitle: "Book clinic visit",
          iconColor: const Color(0xFF14B8A6), // Teal
          bgColor: const Color(0xFFF0FDFA),
          shadowColor: const Color(0xFF14B8A6).withOpacity(0.2), // Teal Glow
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientPhysicalOpdView()),
          ),
        ),
        _buildPremiumCard(
          context: context,
          icon: Icons.videocam_outlined,
          label: "Online Doctors",
          subtitle: "Video consults",
          iconColor: const Color(0xFF10B981), // Emerald
          bgColor: const Color(0xFFECFDF5),
          shadowColor: const Color(0xFF10B981).withOpacity(0.2), // Emerald Glow
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientOnlineDoctorsView()),
          ),
        ),
        _buildPremiumCard(
          context: context,
          icon: Icons.psychology_outlined,
          label: "Search Symptom",
          subtitle: "AI health check",
          iconColor: const Color(0xFF8B5CF6), // Purple
          bgColor: const Color(0xFFF5F3FF),
          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.2), // Purple Glow
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchDoctorBySymptomView()),
          ),
        ),
        _buildPremiumCard(
          context: context,
          icon: Icons.medication_outlined,
          label: "Prescriptions",
          subtitle: "View medications",
          iconColor: const Color(0xFF6366F1), // Indigo
          bgColor: const Color(0xFFEEF2FF),
          shadowColor: const Color(0xFF6366F1).withOpacity(0.2), // Indigo Glow
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PatientPrescriptionsView(userEmail: userEmail)),
          ),
        ),
      ],
    );
  }

  /// 🔹 PREMIUM CARD WIDGET WITH DYNAMIC SHADOW
  Widget _buildPremiumCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor, // 🔥 Dynamic colored glow
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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

  /// 🔹 MEDICAL SUMMARY CARD
  Widget _buildMedicalSummaryCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.12), // Soft friendly blue glow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("Age", data['age']?.toString() ?? "N/A", "Yrs"),
          _buildDivider(),
          _buildSummaryItem("Weight", data['weight']?.toString() ?? "N/A", "Kg"),
          _buildDivider(),
          _buildSummaryItem("Gender", data['gender']?.toString() ?? "N/A", ""),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, String unit) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1.5,
      color: const Color(0xFFF1F5F9), // Softer divider line
    );
  }
}