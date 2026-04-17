import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                : _buildProfile(context, vm),
          );
        },
      ),
    );
  }

  Widget _buildProfile(
      BuildContext context, PatientProfileViewModel vm) {
    final PatientProfileModel patient = vm.patient!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        /// =========================
        /// BASIC INFO
        /// =========================

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

        /// =========================
        /// MEDICAL HISTORY
        /// =========================
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

        const SizedBox(height: 25),

        /// =========================
        /// 📄 REPORTS SECTION
        /// =========================
        const Text(
          "Medical Reports",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: () {
            vm.uploadReport();
          },
          icon: const Icon(Icons.upload_file),
          label: const Text("Upload Report"),
        ),

        const SizedBox(height: 10),

        /// REPORT LIST
        SizedBox(
          height: 320,
          child: StreamBuilder<QuerySnapshot>(
            stream: vm.getReportsStream(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text("No data found"));
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No reports uploaded yet"),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                  docs[index].data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        data['fileType'] == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.image,
                        color: Colors.red,
                      ),
                      title: Text(
                        data['fileName'] ?? "Unnamed File",
                      ),
                      subtitle: const Text("Tap to open/download"),
                      onTap: () {
                        final url = data['fileUrl'];
                        if (url != null) {
                          vm.openReport(url);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
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