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
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("My Profile"),
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.medication), text: "Prescriptions"),
                    Tab(icon: Icon(Icons.assignment), text: "My Reports"),
                  ],
                ),
              ),
              body: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.patient == null
                  ? const Center(child: Text("No Profile Data Found"))
                  : TabBarView(
                children: [
                  _buildPrescriptionTab(context, vm),
                  _buildReportTab(context, vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// =========================
  /// 💊 PRESCRIPTION TAB (NEW)
  /// =========================
  Widget _buildPrescriptionTab(BuildContext context, PatientProfileViewModel vm) {
    return Column(
      children: [
        _buildProfileHeader(vm.patient!),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Doctor's Prescriptions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: vm.getPrescriptionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No prescriptions from doctor yet."));
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final bool isText = data['type'] == 'text';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        isText ? Icons.notes : Icons.image,
                        color: isText ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        isText ? (data['content'] ?? "No content") : (data['fileName'] ?? "Image Prescription"),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(isText ? "Text Note" : "Image File"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isText
                          ? () => _showTextPrescriptionDialog(context, data['content'])
                          : () => vm.openReport(data['fileUrl']),
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

  /// =========================
  /// 📄 REPORTS TAB
  /// =========================
  Widget _buildReportTab(BuildContext context, PatientProfileViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Medical Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: vm.isUploading ? null : () => vm.uploadReport(),
          icon: vm.isUploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file),
          label: Text(vm.isUploading ? "Uploading..." : "Upload New Report"),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: vm.getReportsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No reports uploaded yet"));
            }

            final docs = snapshot.data!.docs;
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      data['fileType'] == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                      color: Colors.red,
                    ),
                    title: Text(data['fileName'] ?? "Unnamed File"),
                    subtitle: const Text("Tap to view"),
                    onTap: () => vm.openReport(data['fileUrl']),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// =========================
  /// PROFILE HEADER & INFO
  /// =========================
  Widget _buildProfileHeader(PatientProfileModel patient) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              title: const Text("Reference Number"),
              subtitle: Text(patient.referenceNumber,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.confirmation_number),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _miniInfoChip("Age: ${patient.age}"),
                _miniInfoChip("BG: ${patient.bloodGroup}"),
                _miniInfoChip("Wt: ${patient.weight}kg"),
                _miniInfoChip(patient.gender),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfoChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(label: Text(label, style: const TextStyle(fontSize: 12))),
    );
  }

  void _showTextPrescriptionDialog(BuildContext context, String? content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Prescription Note"),
        content: Text(content ?? "No details provided"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }
}