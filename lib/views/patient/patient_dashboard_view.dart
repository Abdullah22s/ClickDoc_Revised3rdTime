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
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 👤 USER HEADER
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: userPhotoUrl != null
                                ? NetworkImage(userPhotoUrl!)
                                : const AssetImage(
                                'assets/images/default_avatar.png')
                            as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome back,",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14),
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

                      const SizedBox(height: 20),

                      /// 🔴 EMERGENCY SOS BUTTON (BIG + CLEAR)
                      GestureDetector(
                        onTap: vm.sosLoading
                            ? null
                            : () => vm.sendEmergencySOS(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.warning,
                                  color: Colors.white, size: 35),
                              SizedBox(height: 5),
                              Text(
                                "EMERGENCY SOS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 📦 OTHER FEATURES GRID
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio: 1.2,
                          children: [
                            _gridItem(
                                icon: Icons.person,
                                label: "My Profile",
                                color: Colors.blue,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PatientProfileView(
                                            userEmail: userEmail),
                                  ),
                                )),
                            _gridItem(
                                icon: Icons.local_hospital,
                                label: "Physical OPDs",
                                color: Colors.teal,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const PatientPhysicalOpdView(),
                                  ),
                                )),
                            _gridItem(
                                icon: Icons.video_call,
                                label: "Online Doctors",
                                color: Colors.green,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const PatientOnlineDoctorsView(),
                                  ),
                                )),
                            _gridItem(
                                icon: Icons.psychology,
                                label: "Search by Symptom",
                                color: Colors.deepPurple,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const SearchDoctorBySymptomView(),
                                  ),
                                )),
                          ],
                        ),
                      ),

                      /// 🧾 MEDICAL INFO
                      if (vm.patientData != null) ...[
                        const Text(
                          "Your Medical Info",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoTile("Age", vm.patientData!['age']),
                        _infoTile("Weight", vm.patientData!['weight']),
                        _infoTile("Gender", vm.patientData!['gender']),
                      ]
                    ],
                  ),
                ),
              ),

              /// 🔴 SOS LOADING OVERLAY
              if (vm.sosLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: Colors.redAccent),
                        SizedBox(height: 20),
                        Text(
                          "Sending Emergency SOS...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Recording audio & finding nearby ambulances",
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

  /// 🔹 GRID ITEM
  Widget _gridItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 🔹 INFO TILE
  Widget _infoTile(String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_information,
              color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text("$label: "),
          Text(
            "${value ?? "N/A"}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}