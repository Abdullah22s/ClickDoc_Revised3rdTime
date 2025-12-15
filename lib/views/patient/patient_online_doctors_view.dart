import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/patient/patient_online_viewmodel.dart';
import '../../models/patient/patient_online_model.dart';

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
              backgroundColor: Colors.teal,
            ),
            body: Column(
              children: [
                // 🔍 Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: vm.searchController,
                    decoration: InputDecoration(
                      hintText: "Search by doctor name or department",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: vm.searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: vm.clearSearch,
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: vm.updateSearch,
                  ),
                ),

                // 🩺 Doctors list
                Expanded(
                  child: StreamBuilder(
                    stream: vm.doctorsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No online doctors available."));
                      }

                      final docs = snapshot.data!.docs;

                      return FutureBuilder<List<PatientOnlineModel>>(
                        future: Future.wait(docs.map((doc) => vm.doctorFromSnapshot(doc))),
                        builder: (context, doctorSnapshot) {
                          if (!doctorSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final doctors = doctorSnapshot.data!
                              .where((d) => vm.searchQuery.isEmpty || vm.matchesSearch(d))
                              .toList();

                          if (doctors.isEmpty) {
                            return const Center(child: Text("No doctors match your search."));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              final isExpanded = vm.expandedDoctor[doctor.id] ?? false;

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
                                        backgroundColor: Colors.teal,
                                        child: Icon(Icons.video_call, color: Colors.white),
                                      ),
                                      title: Text("Dr. ${doctor.name}"),
                                      subtitle: Text(
                                          doctor.clinics.isNotEmpty ? doctor.clinics.first.department : 'Not specified'),
                                      trailing: IconButton(
                                        icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                        onPressed: () => vm.toggleDoctorExpansion(doctor.id),
                                      ),
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Column(
                                          children: doctor.clinics
                                              .map((clinic) => ClinicWidget(clinic: clinic, doctorName: doctor.name))
                                              .toList(),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ClinicWidget extends StatelessWidget {
  final ClinicModel clinic;
  final String doctorName;

  const ClinicWidget({super.key, required this.clinic, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Days: ${clinic.days.join(', ')}", style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("Time: ${clinic.startTime} - ${clinic.endTime}"),
          Text("Fees: PKR ${clinic.fees}"),
          const SizedBox(height: 6),
          const Text("Available Slots:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...clinic.slots.map((slot) => Text("${slot['start']} - ${slot['end']}")),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              icon: const Icon(Icons.event_available),
              label: const Text("Book Appointment", style: TextStyle(fontSize: 16)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Booking feature coming soon for Dr. $doctorName")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
