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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🩺 Doctor Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: viewModel.userPhotoUrl != null
                        ? NetworkImage(viewModel.userPhotoUrl!)
                        : const AssetImage('assets/default_user.png')
                    as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. ${viewModel.userName}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 📊 Dashboard Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                  return GridView.builder(
                    itemCount: dashboardItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 130,
                    ),
                    itemBuilder: (context, index) {
                      final item = dashboardItems[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _navigate(context, item.label),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent,
                                Colors.blueAccent.shade200,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 28,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String label) {
    if (label == 'Profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorProfileScreen(
            userEmail: viewModel.userEmail,
          ),
        ),
      );
    } else if (label == 'Appointments') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAppointmentsScreen(),
        ),
      );
    } else if (label == 'Physical OPD') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorPhysicalOpdScreen(),
        ),
      );
    } else if (label == 'Online Clinic') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorOnlineClinicScreen(),
        ),
      );
    }
  }
}
