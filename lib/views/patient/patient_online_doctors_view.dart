import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/patient/patient_online_viewmodel.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';
import 'book_online_appointment_view.dart';

class PatientOnlineDoctorsView extends StatelessWidget {
  const PatientOnlineDoctorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientOnlineViewModel(),
      child: Consumer<PatientOnlineViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Online Doctors"),
              backgroundColor: Colors.blueAccent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog(context, vm);
                  },
                  tooltip: "Filter Doctors",
                ),
              ],
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: vm.doctorsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final doctors = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';

                    return FutureBuilder<List<DoctorOnlineClinicModel>>(
                      future: vm.getDoctorClinics(doc),
                      builder: (context, clinicSnap) {
                        if (!clinicSnap.hasData || clinicSnap.data!.isEmpty) {
                          return const SizedBox();
                        }

                        final clinics = clinicSnap.data!;

                        if (!vm.matchesSearch(name, clinics)) {
                          return const SizedBox();
                        }

                        final isExpanded = vm.expandedDoctor[doc.id] ?? false;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.video_call,
                                      color: Colors.white),
                                ),
                                title: Text(
                                  "Dr. $name",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: clinics.isNotEmpty
                                    ? Text(
                                  clinics.first.department,
                                  style: const TextStyle(
                                      color: Colors.black87),
                                )
                                    : null,
                                trailing: IconButton(
                                  icon: Icon(isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more),
                                  onPressed: () =>
                                      vm.toggleDoctorExpansion(doc.id),
                                ),
                              ),

                              /// ⬇️ ALL CLINICS
                              if (isExpanded)
                                ...clinics.map(
                                      (clinic) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: BookableClinicWidget(clinic: clinic),
                                  ),
                                ),
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

  /// 🔹 Filter Dialog
  void _showFilterDialog(BuildContext context, PatientOnlineViewModel vm) {
    final nameCtrl = TextEditingController(text: vm.nameFilter);
    final deptCtrl = TextEditingController(text: vm.departmentFilter);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter Doctors"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Doctor Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deptCtrl,
              decoration: const InputDecoration(
                labelText: "Department",
                prefixIcon: Icon(Icons.medical_services),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              vm.clearFilters();
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
          ElevatedButton(
            onPressed: () {
              vm.setFilters(
                  name: nameCtrl.text, department: deptCtrl.text);
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Clinic Widget
class BookableClinicWidget extends StatelessWidget {
  final DoctorOnlineClinicModel clinic;

  const BookableClinicWidget({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(clinic.department,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text("Days: ${clinic.days.join(', ')}"),
          Text("Time: ${clinic.startTime} - ${clinic.endTime}"),
          Text("Fees: PKR ${clinic.fees}"),
          const SizedBox(height: 8),
          const Text("Available Slots:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...clinic.slots.map(
                (slot) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text("${slot.start} - ${slot.end}"),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              icon: const Icon(Icons.event_available),
              label: const Text("Book Appointment",
                  style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookOnlineAppointmentView(clinic: clinic),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
