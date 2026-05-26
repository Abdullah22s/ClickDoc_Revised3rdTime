import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/patient/patient_form_model.dart';
import '../../viewmodels/patient/patient_profile_viewmodel.dart';

class PatientProfileView extends StatefulWidget {
  final String userEmail;

  const PatientProfileView({super.key, required this.userEmail});

  @override
  State<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends State<PatientProfileView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientProfileViewModel(userEmail: widget.userEmail),
      child: Consumer<PatientProfileViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text("My Profile")),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.patient == null
                ? const Center(child: Text("No Profile Data Found"))
                : PageView(
              controller: _pageController,
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(vm.patient!),
                      _buildVitalsHistoryBox(),
                      _buildMedicalHistory(vm.patient!),
                      _buildReportSection(context, vm),
                    ],
                  ),
                ),
                _buildVitalsHistoryPage(context, vm),
              ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: const Text(
                "Reference Number",
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                patient.referenceNumber,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
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

  Widget _buildVitalsHistoryBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.cyan.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vitals History",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "View physical and online appointment vitals",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Major Medical History",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
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
              const Text(
                "Medical Reports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed:
                vm.isUploading ? null : () => _showCategoryPicker(context, vm),
                icon: vm.isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.upload_file),
                label: Text(
                  vm.isUploading ? "Uploading..." : "Upload New Report",
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
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
                            const Icon(
                              Icons.folder_open,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
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
    final dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy').format(timestamp.toDate())
        : 'Syncing...';

    final String fileName = data['fileName']?.toString() ?? "File";
    final String fileUrl = data['fileUrl']?.toString() ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          data['fileType']?.toString() == 'pdf'
              ? Icons.picture_as_pdf
              : Icons.image,
          color: Colors.red,
        ),
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text("Date: $dateStr"),
        onTap: () => vm.openReport(fileUrl),
      ),
    );
  }

  Widget _buildVitalsHistoryPage(
      BuildContext context,
      PatientProfileViewModel vm,
      ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: () {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
            const Expanded(
              child: Text(
                "Vitals History",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Your previous physical and online appointment vitals are shown here.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),

        _buildVitalsSection(
          title: "Physical Appointment Vitals",
          stream: vm.getPhysicalVitalsHistoryStream(),
          emptyTitle: "No Physical Vitals Found",
          emptyMessage:
          "Physical vitals will appear here after the operator records them during a clinic appointment.",
          sectionColor: Colors.blue,
          icon: Icons.local_hospital,
          typeLabel: "Physical",
        ),

        const SizedBox(height: 22),

        _buildVitalsSection(
          title: "Online Appointment Vitals",
          stream: vm.getOnlineVitalsHistoryStream(),
          emptyTitle: "No Online Vitals Found",
          emptyMessage:
          "Online vitals will appear here after you submit them before an online appointment.",
          sectionColor: Colors.orange,
          icon: Icons.videocam_rounded,
          typeLabel: "Online",
        ),
      ],
    );
  }

  Widget _buildVitalsSection({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String emptyTitle,
    required String emptyMessage,
    required Color sectionColor,
    required IconData icon,
    required String typeLabel,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: sectionColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: sectionColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              _buildEmptyVitalsBox(
                emptyTitle: emptyTitle,
                emptyMessage: emptyMessage,
                sectionColor: sectionColor,
                icon: icon,
              )
            else
              ...docs.map(
                    (doc) => _buildVitalsCard(
                  doc: doc,
                  sectionColor: sectionColor,
                  icon: icon,
                  typeLabel: typeLabel,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyVitalsBox({
    required String emptyTitle,
    required String emptyMessage,
    required Color sectionColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sectionColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: sectionColor.withOpacity(0.6), size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emptyTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emptyMessage,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard({
    required DocumentSnapshot doc,
    required Color sectionColor,
    required IconData icon,
    required String typeLabel,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    final Map<String, dynamic> vitals =
    Map<String, dynamic>.from(data['vitals'] ?? {});

    final dynamic appointmentDateValue = data['appointmentDate'];

    Timestamp? appointmentTimestamp;
    if (appointmentDateValue is Timestamp) {
      appointmentTimestamp = appointmentDateValue;
    }

    final String dateStr = appointmentTimestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(
      appointmentTimestamp.toDate(),
    )
        : 'Date not available';

    final String doctorName =
        data['doctorName']?.toString() ?? 'Unknown Doctor';

    final String bp = vitals['bp']?.toString() ?? '--';
    final String temp = vitals['temp']?.toString() ?? '--';
    final String spo2 = vitals['spo2']?.toString() ?? '--';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: sectionColor.withOpacity(0.10),
                  child: Icon(
                    icon,
                    color: sectionColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. $doctorName",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sectionColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: sectionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _vitalChip(
                  title: "Blood Pressure",
                  value: bp,
                  unit: "mmHg",
                  icon: Icons.favorite,
                ),
                _vitalChip(
                  title: "Temperature",
                  value: temp,
                  unit: "°F",
                  icon: Icons.thermostat,
                ),
                _vitalChip(
                  title: "SpO2",
                  value: spo2,
                  unit: "%",
                  icon: Icons.air,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalChip({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$value $unit",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, PatientProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Select Category",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...vm.reportCategories.map(
                  (cat) => ListTile(
                title: Text(cat),
                onTap: () {
                  Navigator.pop(context);
                  vm.uploadReport(cat);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}