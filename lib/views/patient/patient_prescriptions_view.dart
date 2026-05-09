import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/patient/patient_prescriptions_viewmodel.dart';

class PatientPrescriptionsView extends StatelessWidget {
  final String userEmail;

  const PatientPrescriptionsView({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientPrescriptionsViewModel(userEmail: userEmail),
      child: Consumer<PatientPrescriptionsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("My Prescriptions"),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.patientId == null
                ? const Center(child: Text("Patient profile not found."))
                : _buildGroupedPrescriptionsList(context, vm),
          );
        },
      ),
    );
  }

  Widget _buildGroupedPrescriptionsList(BuildContext context, PatientPrescriptionsViewModel vm) {
    return StreamBuilder<Map<String, List<QueryDocumentSnapshot>>>(
      stream: vm.getGroupedPrescriptionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No prescriptions yet.", style: TextStyle(color: Colors.grey)));
        }

        final groupedDocs = snapshot.data!;
        final doctorIds = groupedDocs.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctorIds.length,
          itemBuilder: (context, index) {
            final doctorId = doctorIds[index];
            final doctorPrescriptions = groupedDocs[doctorId]!;

            // 🟢 Use FutureBuilder to fetch and show Doctor Name
            return FutureBuilder<String>(
              future: vm.getDoctorName(doctorId),
              builder: (context, nameSnapshot) {
                final doctorName = nameSnapshot.data ?? "Loading...";

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text("Dr. $doctorName", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${doctorPrescriptions.length} Prescription(s)"),
                    children: doctorPrescriptions.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // 🟢 MAPPING FIX: Use your Firestore field names
                      final String? textRx = data['prescriptionText'];
                      final String? imageRx = data['prescriptionImageUrl'];
                      final bool isImage = imageRx != null && imageRx.isNotEmpty;

                      String dateString = "Unknown Date";
                      if (data['createdAt'] != null) {
                        DateTime dt = (data['createdAt'] as Timestamp).toDate();
                        dateString = "${dt.day}/${dt.month}/${dt.year}";
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Card(
                          elevation: 0,
                          color: Colors.grey.shade100,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: !isImage ? Colors.green.shade100 : Colors.orange.shade100,
                              child: Icon(
                                !isImage ? Icons.notes : Icons.image,
                                color: !isImage ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              !isImage ? (textRx ?? "No content") : "Image Prescription",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text("${!isImage ? "Text Note" : "Image File"} • $dateString"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (isImage) {
                                // 🟢 ERROR FIX: Open using correct field name
                                vm.openFile(imageRx!);
                              } else {
                                _showTextPrescriptionDialog(context, textRx, dateString);
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTextPrescriptionDialog(BuildContext context, String? content, String dateStr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Prescription Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: $dateStr", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Text(content ?? "No details provided"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }
}