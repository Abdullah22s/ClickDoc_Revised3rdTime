import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clickdoc1/viewmodels/patient/patient_physical_opd_viewmodel.dart';
import 'package:clickdoc1/models/patient/patient_physical_opd_model.dart';

class PatientPhysicalOpdView extends StatelessWidget {
  const PatientPhysicalOpdView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientPhysicalOpdViewModel(),
      child: Consumer<PatientPhysicalOpdViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Doctors & OPDs"),
              backgroundColor: Colors.blueAccent,
            ),
            body: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: vm.searchController,
                    decoration: InputDecoration(
                      hintText: "Search by doctor, department, or hospital",
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

                // OPDs List
                Expanded(
                  child: StreamBuilder<List<DoctorPhysicalOpdModel>>(
                    stream: vm.doctorOpdStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No OPDs available."));
                      }

                      final doctors =
                      snapshot.data!.where(vm.matchesSearch).toList();

                      if (doctors.isEmpty) {
                        return const Center(child: Text("No matching results."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          final isExpanded =
                              vm.expandedDoctor[doctor.id] ?? false;

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueAccent.shade100,
                                        ),
                                        child: const Icon(
                                          Icons.medical_services,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Dr. ${doctor.name}",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Department: ${doctor.opds.isNotEmpty ? doctor.opds.first.department : 'Unknown'}",
                                              style:
                                              const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () =>
                                            vm.toggleDoctorExpansion(doctor.id),
                                      )
                                    ],
                                  ),
                                ),
                                if (isExpanded)
                                  Column(
                                    children: doctor.opds.map((opd) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 16),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50
                                              .withOpacity(0.5),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${opd.day}: ${opd.hospitalName}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                        FontWeight.w600,
                                                        fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${opd.fromTime} - ${opd.toTime}",
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.local_hospital,
                                                color: Colors.blueAccent),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
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
