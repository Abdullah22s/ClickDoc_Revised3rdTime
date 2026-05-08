import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Required for formatting the date
import '../../viewmodels/doctor/doctor_patient_profile_viewmodel.dart';

class DoctorPatientProfileView extends StatelessWidget {
  final String referenceNumber;
  final String doctorName;

  const DoctorPatientProfileView({
    super.key,
    required this.referenceNumber,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = DoctorPatientProfileViewModel(doctorName: doctorName);
        vm.fetchPatientByReferenceNumber(referenceNumber);
        return vm;
      },
      child: Consumer<DoctorPatientProfileViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (viewModel.patient == null) {
            return const Scaffold(body: Center(child: Text("Patient not found")));
          }

          final patient = viewModel.patient!;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Patient Profile"),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // PROFILE CARD
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : "?",
                              style: const TextStyle(fontSize: 28, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(patient.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Ref: ${patient.referenceNumber}", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INFO TILES
                  Card(
                    child: Column(
                      children: [
                        _tile(Icons.email, "Email", patient.email),
                        _tile(Icons.person, "Gender", patient.gender),
                        _tile(Icons.cake, "Age", "${patient.age}"),
                        _tile(Icons.monitor_weight, "Weight", "${patient.weight} kg"),
                        _tile(Icons.bloodtype, "Blood Group", patient.bloodGroup),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CATEGORIZED REPORTS SECTION
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Medical Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  _buildReports(viewModel),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildReports(DoctorPatientProfileViewModel viewModel) {
    return StreamBuilder<QuerySnapshot>(
      stream: viewModel.getReportsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Card(child: ListTile(title: Text("No reports found")));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: viewModel.reportCategories.map((category) {
            // Filter docs by category
            final categoryDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['category']?.toString() == category;
            }).toList();

            // If a category has no reports, don't render its header
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
                ...categoryDocs.map((doc) => _buildReportTile(doc, viewModel)),
                const SizedBox(height: 10),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReportTile(DocumentSnapshot doc, DoctorPatientProfileViewModel viewModel) {
    final data = doc.data() as Map<String, dynamic>;

    // Formatting the date
    final timestamp = data['uploadedAt'] as Timestamp?;
    final dateStr = timestamp != null ? DateFormat('dd MMM yyyy').format(timestamp.toDate()) : 'Syncing...';

    final String fileName = data['fileName']?.toString() ?? "File";
    final String fileUrl = data['fileUrl']?.toString() ?? "";
    final bool isPdf = data['fileType']?.toString() == 'pdf' || fileName.toLowerCase().endsWith('.pdf');

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
            isPdf ? Icons.picture_as_pdf : Icons.image,
            color: Colors.red
        ),
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text("Date: $dateStr"),
        onTap: () => viewModel.openFile(fileUrl),
      ),
    );
  }
}