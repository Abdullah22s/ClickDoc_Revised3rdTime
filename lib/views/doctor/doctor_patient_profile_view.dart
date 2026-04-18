import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            body: Stack(
              children: [
                SingleChildScrollView(
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
                      const SizedBox(height: 16),

                      // REPORTS SECTION
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("  Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _buildReports(viewModel),
                      const SizedBox(height: 16),

                      // PRESCRIPTIONS SECTION
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("  Prescriptions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _buildPrescriptions(viewModel),
                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),

                // LOADING OVERLAY
                if (viewModel.isUploading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 15),
                              Text("Uploading to Storage..."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ACTION BUTTONS AT BOTTOM
            bottomSheet: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isUploading ? null : () => _showPrescriptionDialog(context, viewModel),
                      icon: const Icon(Icons.edit),
                      label: const Text("Write"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isUploading ? null : () => viewModel.pickAndUploadPrescriptionFile(),
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(child: ListTile(title: Text("No reports found")));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(data['fileName'] ?? "Report"),
                onTap: () => viewModel.openFile(data['fileUrl']),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPrescriptions(DoctorPatientProfileViewModel viewModel) {
    return StreamBuilder<QuerySnapshot>(
      stream: viewModel.getPrescriptionsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(child: ListTile(title: Text("No prescriptions found")));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isText = data['type'] == 'text';
            return Card(
              child: ListTile(
                leading: Icon(isText ? Icons.notes : Icons.image, color: isText ? Colors.green : Colors.orange),
                title: Text(isText ? (data['content'] ?? "") : (data['fileName'] ?? "File")),
                onTap: isText ? null : () => viewModel.openFile(data['fileUrl']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => viewModel.deletePrescriptionWithFile(doc.id, data['fileUrl']),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showPrescriptionDialog(BuildContext context, DoctorPatientProfileViewModel viewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Write Prescription"),
        content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: "Enter details...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await viewModel.addTextPrescription(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}