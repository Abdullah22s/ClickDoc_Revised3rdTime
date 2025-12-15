import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/patient/patient_profile_viewmodel.dart';

class PatientProfileView extends StatelessWidget {
  final String userEmail;

  const PatientProfileView({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientProfileViewModel(userEmail: userEmail),
      child: Consumer<PatientProfileViewModel>(
        builder: (context, vm, _) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("My Profile"),
                backgroundColor: Colors.blueAccent,
                bottom: const TabBar(
                  labelColor: Colors.white,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: "My Info"),
                    Tab(text: "My Reports"),
                  ],
                ),
              ),
              body: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                children: [
                  _buildMyInfo(vm),
                  _buildMyReports(vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyInfo(PatientProfileViewModel vm) {
    if (vm.patient == null) {
      return const Center(
        child: Text("No Data Found", style: TextStyle(fontSize: 16)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile("Email", vm.patient!.email),
        _infoTile("Age", vm.patient!.age),
        _infoTile("Weight", vm.patient!.weight),
        _infoTile("Gender", vm.patient!.gender),
        _infoTile("Medical History", vm.patient!.medicalHistory),
      ],
    );
  }

  Widget _buildMyReports(PatientProfileViewModel vm) {
    return const Center(
      child: Text(
        "Reports section coming soon...",
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _infoTile(String label, dynamic value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value?.toString() ?? "N/A"),
        leading: const Icon(Icons.arrow_right, color: Colors.blueAccent),
      ),
    );
  }
}
