import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/doctor/doctor_current_patients_viewmodel.dart';
import 'doctor_patient_profile_view.dart';

class DoctorCurrentPatientsView extends StatelessWidget {
  const DoctorCurrentPatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorCurrentPatientsViewModel(),
      child: Consumer<DoctorCurrentPatientsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Current Patients"),
              backgroundColor: Colors.blueAccent,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: vm.getPatientsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No patients yet",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final patients = snapshot.data!.docs.toList();

                /// sort newest first
                patients.sort((a, b) {
                  final aTime =
                  (a['acceptedAt'] as Timestamp?)?.toDate();
                  final bTime =
                  (b['acceptedAt'] as Timestamp?)?.toDate();

                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final data = patients[index];

                    final reference = data['referenceNumber'] ?? '';
                    final patientId = data['patientId'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.shade100,
                          child: Text(
                            reference.isNotEmpty
                                ? reference[0].toUpperCase()
                                : "?",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        title: Text(
                          "Ref: $reference",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: const Text(
                          "Tap to view patient profile",
                          style: TextStyle(fontSize: 12),
                        ),

                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorPatientProfileView(
                                referenceNumber: reference,
                              ),
                            ),
                          );
                        },
                      ),
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
}