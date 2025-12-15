import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/doctor/doctor_profile_viewmodel.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String userEmail;

  const DoctorProfileScreen({super.key, required this.userEmail});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorProfileViewModel(userEmail: widget.userEmail),
      child: Consumer<DoctorProfileViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("My Profile"),
              backgroundColor: Colors.blueAccent,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: "My Info"),
                  Tab(text: "My Patients"),
                ],
              ),
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildMyInfo(vm),
                _buildMyPatients(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyInfo(DoctorProfileViewModel vm) {
    if (vm.doctorProfile == null) {
      return const Center(
        child: Text("No Data Found", style: TextStyle(fontSize: 16)),
      );
    }

    final doctor = vm.doctorProfile!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile("Email", doctor.email),
        _infoTile("Phone", doctor.phone),
        _infoTile("Qualifications", doctor.qualifications.join(', ')),
        _infoTile("Experience", doctor.experience),
      ],
    );
  }

  Widget _buildMyPatients() {
    return const Center(
      child: Text(
        "Patients section coming soon...",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isNotEmpty ? value : "N/A"),
        leading: const Icon(Icons.arrow_right, color: Colors.blueAccent),
      ),
    );
  }
}
