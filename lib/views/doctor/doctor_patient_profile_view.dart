import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/doctor/doctor_patient_profile_viewmodel.dart';

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

                  // =========================
                  // PATIENT INFO (YOUR ORIGINAL SECTION KEPT)
                  // =========================
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Ref: ${patient.referenceNumber}"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // BASIC INFO (PRESERVED)
                  // =========================
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text("Email"),
                          subtitle: Text(patient.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text("Gender"),
                          subtitle: Text(patient.gender),
                        ),
                        ListTile(
                          leading: const Icon(Icons.cake),
                          title: const Text("Age"),
                          subtitle: Text("${patient.age}"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.monitor_weight),
                          title: const Text("Weight"),
                          subtitle: Text("${patient.weight} kg"),
                        ),
                        ListTile(
                          leading: const Icon(Icons.bloodtype),
                          title: const Text("Blood Group"),
                          subtitle: Text(patient.bloodGroup),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // MEDICAL HISTORY (PRESERVED)
                  // =========================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Medical History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          patient.medicalHistory.isEmpty
                              ? const Text("No medical history")
                              : Wrap(
                            spacing: 6,
                            children: patient.medicalHistory
                                .map((e) => Chip(label: Text(e)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // REPORTS (ADDED)
                  // =========================
                  _buildReports(patient.id),

                  const SizedBox(height: 16),

                  // =========================
                  // PRESCRIPTIONS (ADDED)
                  // =========================
                  _buildPrescriptions(patient.id),

                  const SizedBox(height: 20),

                  // =========================
                  // ADD PRESCRIPTION BUTTON (ADDED)
                  // =========================
                  ElevatedButton.icon(
                    onPressed: () {
                      _showPrescriptionDialog(context, patient.id);
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text("Add Prescription"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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

  // =========================
  // REPORTS SECTION
  // =========================
  Widget _buildReports(String patientId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reports",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(patientId)
                  .collection('reports')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No reports");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(data['fileName']),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // PRESCRIPTIONS SECTION
  // =========================
  Widget _buildPrescriptions(String patientId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Prescriptions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(patientId)
                  .collection('prescriptions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No prescriptions yet");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];

                    return ListTile(
                      leading: Icon(
                        data['type'] == 'image'
                            ? Icons.image
                            : Icons.description,
                      ),
                      title: Text(
                        data['type'] == 'image'
                            ? "Image Prescription"
                            : data['content'],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // ADD PRESCRIPTION DIALOG
  // =========================
  void _showPrescriptionDialog(BuildContext context, String patientId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Prescription"),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Write prescription...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('patients')
                      .doc(patientId)
                      .collection('prescriptions')
                      .add({
                    'type': 'text',
                    'content': controller.text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}