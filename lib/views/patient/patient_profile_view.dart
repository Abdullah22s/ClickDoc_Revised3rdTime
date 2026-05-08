import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/patient/patient_form_model.dart';
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
            appBar: AppBar(title: const Text("My Profile")),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.patient == null
                ? const Center(child: Text("No Profile Data Found"))
                : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(vm.patient!),
                  _buildMedicalHistory(vm.patient!),
                  _buildReportSection(context, vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(PatientFormModel patient) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              title: const Text("Reference Number", style: TextStyle(fontSize: 14)),
              subtitle: Text(patient.referenceNumber,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _miniInfoChip("Age: ${patient.age}"),
              _miniInfoChip("Blood: ${patient.bloodGroup}"),
              _miniInfoChip("Weight: ${patient.weight}kg"),
              _miniInfoChip(patient.gender),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfoChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildMedicalHistory(PatientFormModel patient) {
    final String historyText = patient.medicalHistory.isNotEmpty
        ? patient.medicalHistory.join(", ")
        : "No major illnesses reported.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.red.shade100),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text("Major Medical History",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const Divider(),
              Text(
                historyText,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(BuildContext context, PatientProfileViewModel vm) {
    return StreamBuilder<QuerySnapshot>(
      stream: vm.getReportsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Medical Reports",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: vm.isUploading ? null : () => _showCategoryPicker(context, vm),
                icon: vm.isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: Text(vm.isUploading ? "Uploading..." : "Upload New Report"),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 20),

              if (docs.isEmpty && !vm.isUploading)
                const Center(child: Text("No reports uploaded yet"))
              else
                ...vm.reportCategories.map((category) {
                  final categoryDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category']?.toString() == category;
                  }).toList();

                  if (categoryDocs.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_open, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(category, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                      ...categoryDocs.map((doc) => _buildReportTile(doc, vm)),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportTile(DocumentSnapshot doc, PatientProfileViewModel vm) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['uploadedAt'] as Timestamp?;
    final dateStr = timestamp != null ? DateFormat('dd MMM yyyy').format(timestamp.toDate()) : 'Syncing...';

    final String fileName = data['fileName']?.toString() ?? "File";
    final String fileUrl = data['fileUrl']?.toString() ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
            data['fileType']?.toString() == 'pdf' ? Icons.picture_as_pdf : Icons.image,
            color: Colors.red
        ),
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text("Date: $dateStr"),
        onTap: () => vm.openReport(fileUrl),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, PatientProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Select Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...vm.reportCategories.map((cat) => ListTile(
              title: Text(cat),
              onTap: () {
                Navigator.pop(context);
                vm.uploadReport(cat);
              },
            )),
          ],
        ),
      ),
    );
  }
}