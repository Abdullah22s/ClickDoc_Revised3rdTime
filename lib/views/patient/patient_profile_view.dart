import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/patient/patient_profile_model.dart';
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
          return Scaffold(
            appBar: AppBar(
              title: const Text("My Profile"),
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.patient == null
                ? const Center(child: Text("No Profile Data Found"))
                : _buildProfile(vm.patient!),
          );
        },
      ),
    );
  }

  Widget _buildProfile(PatientProfileModel patient) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        /// Reference Number
        Card(
          color: Colors.blue.shade50,
          child: ListTile(
            title: const Text("Reference Number"),
            subtitle: Text(
              patient.referenceNumber,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const Icon(Icons.confirmation_number),
          ),
        ),

        const SizedBox(height: 16),

        _infoCard("Email", patient.email),
        _infoCard("Age", patient.age),
        _infoCard("Weight (kg)", patient.weight),
        _infoCard("Gender", patient.gender),
        _infoCard("Blood Group", patient.bloodGroup),

        const SizedBox(height: 16),

        /// Medical History
        const Text(
          "Major Illnesses",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        patient.medicalHistory.isEmpty
            ? const Text("No major illness reported")
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: patient.medicalHistory.map((disease) {
            return Chip(
              label: Text(disease),
              backgroundColor: Colors.red.shade50,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        leading: const Icon(Icons.arrow_right),
      ),
    );
  }
}
