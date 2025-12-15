import 'package:flutter/material.dart';
import '../../viewmodels/doctor/doctor_dashboard_viewmodel.dart';
import 'doctor_profile_view.dart';
import 'doctor_physical_opd_view.dart';
import 'doctor_online_clinic_view.dart';
import 'doctor_appointments_view.dart';

class DoctorDashboardScreen extends StatelessWidget {
  final DoctorDashboardViewModel viewModel;

  const DoctorDashboardScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final dashboardItems = viewModel.dashboardItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: viewModel.userPhotoUrl != null
                      ? NetworkImage(viewModel.userPhotoUrl!)
                      : const AssetImage('assets/default_user.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Text(
                  "Welcome Dr. ${viewModel.userName}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = (constraints.maxWidth / 100).floor();
                  if (crossAxisCount < 2) crossAxisCount = 2;

                  return GridView.builder(
                    itemCount: dashboardItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 90,
                    ),
                    itemBuilder: (context, index) {
                      final item = dashboardItems[index];

                      return GestureDetector(
                        onTap: () {
                          if (item.label == 'Profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorProfileScreen(
                                  userEmail: viewModel.userEmail,
                                ),
                              ),
                            );
                          }
                          else if (item.label == 'Appointments') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorAppointmentsScreen(),
                              ),
                            );
                          }
                          else if (item.label == 'Physical OPD') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorPhysicalOpdScreen(),
                              ),
                            );
                          }
                          else if (item.label == 'Online Clinic') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorOnlineClinicScreen(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.shade100,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(1, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, size: 24, color: Colors.white),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }
}
