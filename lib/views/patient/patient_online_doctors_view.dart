import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              backgroundColor: Colors.teal,
            ),
            body: Column(
              children: [
                // Search bar
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
                // Doctors List
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

                      return FutureBuilder<List<DoctorOnlineClinicModel>>(
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
                                      title: Text("Dr. ${doctor.doctorName}"),
                                      subtitle: Text(doctor.department),
                                      trailing: IconButton(
                                        icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                        onPressed: () => vm.toggleDoctorExpansion(doctor.id),
                                      ),
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Column(
                                          children: [
                                            BookableClinicWidget(clinic: doctor),
                                          ],
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

// Each clinic card with Book button
class BookableClinicWidget extends StatelessWidget {
  final DoctorOnlineClinicModel clinic;

  const BookableClinicWidget({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(clinic.department, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text("Days: ${clinic.days.join(', ')}"),
          Text("Time: ${clinic.startTime} - ${clinic.endTime}"),
          Text("Fees: PKR ${clinic.fees}"),
          const SizedBox(height: 8),
          const Text("Available Slots:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // Show all slots
          ...clinic.slots.map(
                (slot) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text("${slot.start} - ${slot.end}"),
            ),
          ),
          const SizedBox(height: 12),
          // Single "Book Appointment" button
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
