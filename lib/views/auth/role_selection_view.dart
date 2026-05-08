import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/role_selection_viewmodel.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String? userName;
  const RoleSelectionScreen({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoleSelectionViewModel(),
      child: Consumer<RoleSelectionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Select Your Role',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  onPressed: () => vm.signOut(context),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${userName ?? 'User'} 👋',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('How would you like to use ClickDoc today?',
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _roleCard(
                          context,
                          title: "Doctor",
                          icon: Icons.medical_services_rounded,
                          color: const Color(0xFF1976D2),
                          onTap: () => vm.handleDoctorSelection(context),
                        ),
                        _roleCard(
                          context,
                          title: "Patient",
                          icon: Icons.person_rounded,
                          color: const Color(0xFF43A047),
                          onTap: () => vm.handlePatientSelection(context, userName),
                        ),
                        _roleCard(
                          context,
                          title: "Ambulance",
                          icon: Icons.local_shipping_rounded,
                          color: const Color(0xFFD32F2F),
                          onTap: () => vm.handleAmbulanceSelection(context),
                        ),
                        _roleCard(
                          context,
                          title: "Operator",
                          icon: Icons.support_agent_rounded,
                          color: const Color(0xFFFB8C00),
                          onTap: () => vm.handleOperatorSelection(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _roleCard(BuildContext context,
      {required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}