import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/patient/patient_dashboard_viewmodel.dart';
import '../../views/patient/patient_profile_view.dart';
import '../../views/patient/patient_physical_opd_view.dart';
import '../../views/patient/patient_online_doctors_view.dart';
import '../../views/patient/search_doctor_by_symptom_view.dart';

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
          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.blueAccent,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => vm.signOut(context),
                  ),
                  title: const Text(
                    "Patient Dashboard",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                body: vm.isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // USER HEADER
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: userPhotoUrl != null
                                ? NetworkImage(userPhotoUrl!)
                                : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome back,",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 25),

                      // GRID ITEMS
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int cross = (constraints.maxWidth / 130).floor();
                            if (cross < 2) cross = 2;

                            return GridView.builder(
                              itemCount: vm.dashboardItems.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cross,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                mainAxisExtent: 120,
                              ),
                              itemBuilder: (context, i) {
                                final item = vm.dashboardItems[i];
                                return GestureDetector(
                                  onTap: () => _handleNavigation(context, vm, item.label),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: item.gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: item.gradient.last.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(item.icon, size: 35, color: Colors.white),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.label,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // PATIENT MEDICAL INFO SECTION
                      if (vm.patientData != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Your Medical Info",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _infoTile("Age", vm.patientData!['age']),
                        _infoTile("Weight", vm.patientData!['weight']),
                        _infoTile("Gender", vm.patientData!['gender']),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),

              // SOS LOADING OVERLAY
              if (vm.sosLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.redAccent),
                        SizedBox(height: 20),
                        Text(
                          "Recording & Sending SOS...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Please hold for 5 seconds",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// ----------------------------------------------------------
  /// 🔹 NAVIGATION & SOS LOGIC
  /// ----------------------------------------------------------
  void _handleNavigation(BuildContext context, PatientDashboardViewModel vm, String label) {
    switch (label) {
      case 'My Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatientProfileView(userEmail: userEmail)),
        );
        break;
      case 'Physical OPDs':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientPhysicalOpdView()),
        );
        break;
      case 'Online Doctors':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientOnlineDoctorsView()),
        );
        break;
      case 'Search by Symptom':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchDoctorBySymptomView()),
        );
        break;
      case 'Emergency SOS':
      // Trigger the SOS function from ViewModel
        vm.sendEmergencySOS(context);
        break;
    }
  }

  Widget _infoTile(String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_information, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            "${value ?? "N/A"}",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}