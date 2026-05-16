import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clickdoc1/viewmodels/patient/patient_physical_opd_viewmodel.dart';
import 'package:clickdoc1/models/patient/patient_physical_opd_model.dart';
// Ensure this import points to your new booking view file
import 'bookphysicalappointmentview.dart';

class PatientPhysicalOpdView extends StatefulWidget {
  const PatientPhysicalOpdView({super.key});

  @override
  State<PatientPhysicalOpdView> createState() => _PatientPhysicalOpdViewState();
}

class _PatientPhysicalOpdViewState extends State<PatientPhysicalOpdView> {
  String _name = '';
  String _department = '';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientPhysicalOpdViewModel(),
      child: Consumer<PatientPhysicalOpdViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Physical OPDs"),
              backgroundColor: Colors.blueAccent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _openFilterSheet(context, vm),
                ),
              ],
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: vm.doctorsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Doctors available."));
                }

                final doctorDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: doctorDocs.length,
                  itemBuilder: (context, index) {
                    final doc = doctorDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final doctorName = data['name'] ?? 'Unknown';

                    final List qualificationsList = data['qualifications'] ?? [];
                    final qualificationsText = qualificationsList.isNotEmpty
                        ? " (${qualificationsList.join(', ')})"
                        : "";

                    return FutureBuilder<List<PhysicalOpdModel>>(
                      future: vm.getDoctorOpds(doc),
                      builder: (context, opdSnapshot) {
                        if (!opdSnapshot.hasData) return const SizedBox();
                        final opds = opdSnapshot.data!;

                        if (opds.isEmpty) return const SizedBox();

                        if (!vm.matchesSearch(doctorName, opds)) {
                          return const SizedBox();
                        }

                        final isExpanded = vm.expandedDoctor[doc.id] ?? false;
                        final firstOpd = opds.first;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.local_hospital),
                                title: Text(
                                  "Dr. $doctorName$qualificationsText",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Department: ${firstOpd.department}"),
                                    Text("City: ${firstOpd.city}"),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more),
                                  onPressed: () =>
                                      vm.toggleDoctorExpansion(doc.id),
                                ),
                              ),
                              if (isExpanded)
                                ...opds.map((opd) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(opd.hospitalName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                                            Text(opd.day, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text("Time: ${opd.fromTime} - ${opd.toTime}"),
                                        const SizedBox(height: 10),
                                        const Text("Available Slots:", style: TextStyle(fontWeight: FontWeight.bold)),
                                        // Preview of slots
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            opd.slots.take(3).map((s) => "${s['start']}").join(", ") + (opd.slots.length > 3 ? "..." : ""),
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.calendar_month, size: 18),
                                            label: const Text("Book Appointment"),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => BookPhysicalAppointmentView(
                                                    doctorId: doc.id,
                                                    opdId: opd.id,
                                                    opd: opd,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(double.infinity, 45),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openFilterSheet(BuildContext context, PatientPhysicalOpdViewModel vm) {
    final nameCtrl = TextEditingController(text: _name);
    final deptCtrl = TextEditingController(text: _department);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Doctor Name"),
              ),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: "Department"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _name = nameCtrl.text;
                    _department = deptCtrl.text;
                  });
                  vm.setFilters(name: _name, department: _department);
                  Navigator.pop(context);
                },
                child: const Text("Apply Filters"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _name = '';
                    _department = '';
                  });
                  vm.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text("Clear Filters"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}