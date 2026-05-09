import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/doctor/doctor_current_patients_viewmodel.dart';

class DoctorCurrentPatientsView extends StatelessWidget {
  final Color primaryPurple = const Color(0xFF7C3AED);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate600 = const Color(0xFF475569);

  const DoctorCurrentPatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorCurrentPatientsViewModel(),
      child: Consumer<DoctorCurrentPatientsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text("Patient History", style: TextStyle(fontWeight: FontWeight.w800)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.calendar_month, color: primaryPurple),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: viewModel.selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) viewModel.updateDate(picked);
                  },
                )
              ],
            ),
            body: Column(
              children: [
                _buildHeader(viewModel),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: viewModel.patientsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return _buildPatientCard(context, data, viewModel);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Map<String, dynamic> data, DoctorCurrentPatientsViewModel viewModel) {
    final String patientId = data['patientId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<String>(
          future: viewModel.getPatientName(patientId),
          builder: (context, nameSnapshot) {
            final String name = nameSnapshot.data ?? "Loading...";
            final String initial = name.isNotEmpty ? name[0] : "P";

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showActionOptions(context, viewModel, data, name),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    // 🟢 Personalized Avatar
                    Container(
                      height: 52, width: 52,
                      decoration: BoxDecoration(color: primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(initial.toUpperCase(), style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 20))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🟢 Patient Name as primary title
                          Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 17)),
                          const SizedBox(height: 2),
                          // 🟢 Sub-details: Ref ID and Department
                          Text(
                            "Ref: ${data['referenceNumber']} • ${data['department'] ?? 'General'}",
                            style: TextStyle(color: slate600, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text("Seen at ${data['slotStart']}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert, color: slate600.withOpacity(0.4)),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  void _showActionOptions(BuildContext context, DoctorCurrentPatientsViewModel viewModel, Map<String, dynamic> data, String patientName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Update $patientName", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            _actionTile(Icons.edit_note, "Write Prescription", Colors.blue, () {
              Navigator.pop(context);
              _showManualPrescriptionDialog(context, viewModel, data['patientId'], patientName);
            }),
            _actionTile(Icons.cloud_upload, "Upload Prescription Image", Colors.green, () {
              Navigator.pop(context);
              _handlePrescriptionUpload(context, viewModel, data['patientId'], patientName);
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  void _showManualPrescriptionDialog(BuildContext context, DoctorCurrentPatientsViewModel viewModel, String patientId, String name) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Rx for $name"),
        content: TextField(controller: controller, maxLines: 4, decoration: InputDecoration(hintText: "Enter meds...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await viewModel.savePrescription(patientId: patientId, prescriptionText: controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save Rx", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrescriptionUpload(BuildContext context, DoctorCurrentPatientsViewModel viewModel, String patientId, String name) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;
      if (context.mounted) showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        await viewModel.savePrescription(patientId: patientId, prescriptionImageFile: File(image.path));
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rx uploaded for $name")));
        }
      } finally {
        if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildHeader(DoctorCurrentPatientsViewModel viewModel) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(children: [Icon(Icons.calendar_today, size: 16, color: slate600), const SizedBox(width: 8), Text(DateFormat('EEEE, MMM d').format(viewModel.selectedDate), style: TextStyle(color: slate600, fontWeight: FontWeight.bold))]),
  );
  Widget _buildErrorState(String error) => Center(child: Text(error.contains('index') ? "Building database index..." : "Error: $error"));
  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_off, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), const Text("No patients recorded for this day.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
}