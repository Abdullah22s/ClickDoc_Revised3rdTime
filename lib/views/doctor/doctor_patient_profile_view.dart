import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/doctor/doctor_patient_profile_viewmodel.dart';
import '../../models/patient/patient_model.dart';

class DoctorPatientProfileView extends StatelessWidget {
  final String referenceNumber;

  const DoctorPatientProfileView({super.key, required this.referenceNumber});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = DoctorPatientProfileViewModel();
        vm.fetchPatientByReferenceNumber(referenceNumber);
        return vm;
      },
      child: Consumer<DoctorPatientProfileViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (viewModel.patient == null) {
            return const Scaffold(
              body: Center(child: Text("Patient not found")),
            );
          }

          final patient = viewModel.patient!;
          return Scaffold(
            appBar: AppBar(
              title: const Text("Patient Profile"),
              backgroundColor: Colors.blueAccent,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Name and Reference Number
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blueAccent.shade100,
                            child: Text(
                              patient.name.isNotEmpty
                                  ? patient.name[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                  fontSize: 32, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            patient.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Reference No: ${patient.referenceNumber}",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Basic Info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email, color: Colors.blue),
                          title: const Text("Email"),
                          subtitle: Text(patient.email),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: const Text("Gender"),
                          subtitle: Text(patient.gender),
                        ),
                        const Divider(),
                        ListTile(
                          leading:
                          const Icon(Icons.cake, color: Colors.blueAccent),
                          title: const Text("Age"),
                          subtitle: Text("${patient.age} years"),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.monitor_weight,
                              color: Colors.blueAccent),
                          title: const Text("Weight"),
                          subtitle: Text("${patient.weight} kg"),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.bloodtype,
                              color: Colors.redAccent),
                          title: const Text("Blood Group"),
                          subtitle: Text(patient.bloodGroup),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medical History
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Medical History",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          patient.medicalHistory.isEmpty
                              ? const Text(
                            "No major illness reported",
                            style: TextStyle(color: Colors.grey),
                          )
                              : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                            patient.medicalHistory.map((disease) {
                              return Chip(
                                label: Text(disease),
                                backgroundColor: Colors.red.shade50,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
