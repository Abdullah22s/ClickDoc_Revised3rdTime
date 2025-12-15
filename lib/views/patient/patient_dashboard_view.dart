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
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blueAccent,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => vm.signOut(context),
              ),
              title: const Text("Patient Dashboard"),
            ),
            body: vm.isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
                : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: userPhotoUrl != null
                            ? NetworkImage(userPhotoUrl!)
                            : const AssetImage(
                            'assets/images/default_avatar.png')
                        as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Welcome, $userName",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // GRID ITEMS
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int cross =
                        (constraints.maxWidth / 130).floor();
                        if (cross < 2) cross = 2;

                        return GridView.builder(
                          itemCount: vm.dashboardItems.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 110,
                          ),
                          itemBuilder: (context, i) {
                            final item = vm.dashboardItems[i];
                            return GestureDetector(
                              onTap: () {
                                if (item.label == 'My Profile') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PatientProfileView(
                                            userEmail: userEmail,
                                          ),
                                    ),
                                  );
                                } else if (item.label ==
                                    'Physical OPDs') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const PatientPhysicalOpdView(),
                                    ),
                                  );
                                } else if (item.label ==
                                    'Online Doctors') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const PatientOnlineDoctorsView(),
                                    ),
                                  );
                                } else if (item.label ==
                                    'Search by Symptom') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const SearchDoctorBySymptomView(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: item.gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(item.icon,
                                        size: 30, color: Colors.white),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 14,
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

                  // PATIENT INFO
                  if (vm.patientData != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      "Your Medical Info",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _infoTile("Age", vm.patientData!['age']),
                    _infoTile("Weight", vm.patientData!['weight']),
                    _infoTile("Gender", vm.patientData!['gender']),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: ${value ?? "N/A"}",
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
