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

  /// Builds the grouped list of prescriptions from Firestore
  Widget _buildGroupedPrescriptionsList(BuildContext context, PatientPrescriptionsViewModel vm) {
    return StreamBuilder<Map<String, List<QueryDocumentSnapshot>>>(
      stream: vm.getGroupedPrescriptionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No prescriptions from any doctor yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final groupedDocs = snapshot.data!;
        final doctorNames = groupedDocs.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctorNames.length,
          itemBuilder: (context, index) {
            final doctorName = doctorNames[index];
            final doctorPrescriptions = groupedDocs[doctorName]!;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                initiallyExpanded: index == 0, // Expand the most recent doctor by default
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  "Dr. $doctorName",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text("${doctorPrescriptions.length} Prescription(s)"),
                children: doctorPrescriptions.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isText = data['type'] == 'text';

                  // Helper to format date if timestamp exists
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isText ? Colors.green.shade100 : Colors.orange.shade100,
                          child: Icon(
                            isText ? Icons.notes : Icons.image,
                            color: isText ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          isText ? (data['content'] ?? "No content") : (data['fileName'] ?? "Image Prescription"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "${isText ? "Text Note" : "Image File"} • $dateString",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: isText
                            ? () => _showTextPrescriptionDialog(context, data['content'], dateString)
                            : () => vm.openFile(data['fileUrl']),
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
  }

  /// Shows text-based prescriptions in a popup dialog
  void _showTextPrescriptionDialog(BuildContext context, String? content, String dateStr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.medication, color: Colors.blue),
            SizedBox(width: 8),
            Text("Prescription Note"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Date: $dateStr",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                content ?? "No details provided",
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }
}
