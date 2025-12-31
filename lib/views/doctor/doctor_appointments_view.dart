import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodels/doctor/doctor_appointments_viewmodel.dart';
import '../../models/doctor/appointment_model.dart';
import 'doctor_patient_profile_view.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  final DoctorAppointmentsViewModel viewModel = DoctorAppointmentsViewModel();

  DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Online Clinics"),
        backgroundColor: Colors.blueAccent,
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.appointments.isEmpty) {
            return const Center(child: Text("No online clinics found."));
          }

          return ListView.builder(
            itemCount: viewModel.appointments.length,
            itemBuilder: (context, index) {
              final clinic = viewModel.appointments[index];

              // 🔹 Delete past clinics automatically
              final now = DateTime.now();
              if (clinic.endDateTime.isBefore(now)) {
                FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('online_clinics')
                    .doc(clinic.id)
                    .delete();
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clinic #${index + 1}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text("Days: ${clinic.days.join(', ')}"),
                      Text("Time: ${clinic.startTime} - ${clinic.endTime}"),
                      Text("Fees: Rs ${clinic.fees}"),
                      const SizedBox(height: 10),
                      const Text("Slots:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),

                      ...clinic.slots.map((slot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('doctors')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('online_clinics')
                              .doc(clinic.id)
                              .collection('appointments')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();

                            final requests = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['start'] == slot.start &&
                                  data['end'] == slot.end;
                            }).toList();

                            return Card(
                              color: Colors.grey[50],
                              margin:
                              const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: SizedBox(
                                height: 70,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "${slot.start} - ${slot.end}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                      ...requests.map((requestDoc) {
                                        final data = requestDoc.data()
                                        as Map<String, dynamic>;
                                        final status =
                                            data['status'] ?? 'pending';
                                        final patientId =
                                            data['patientId'] ?? '';

                                        return Row(
                                          children: [
                                            Visibility(
                                              visible: status == 'pending',
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                    Colors.green),
                                                onPressed: () async {
                                                  final smsSent =
                                                  await viewModel
                                                      .handleAppointment(
                                                    clinicId: clinic.id,
                                                    appointmentId:
                                                    requestDoc.id,
                                                    action: 'accept',
                                                  );

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        smsSent
                                                            ? "Appointment accepted and SMS sent to patient."
                                                            : "Appointment accepted, but SMS failed.",
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text("Accept"),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Visibility(
                                              visible: status == 'pending',
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                    Colors.red),
                                                onPressed: () {
                                                  viewModel.handleAppointment(
                                                    clinicId: clinic.id,
                                                    appointmentId:
                                                    requestDoc.id,
                                                    action: 'reject',
                                                  );
                                                },
                                                child: const Text("Reject"),
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            if (patientId.isNotEmpty)
                                              FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('patients')
                                                    .doc(patientId)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  String refNumber =
                                                      'Loading...';
                                                  if (snapshot.hasData &&
                                                      snapshot
                                                          .data!.exists) {
                                                    refNumber = (snapshot.data!
                                                        .data() as Map<
                                                        String,
                                                        dynamic>)['referenceNumber'] ??
                                                        'N/A';
                                                  }

                                                  return ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: status ==
                                                          'accepted'
                                                          ? Colors.green
                                                          : Colors.blueAccent,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              DoctorPatientProfileView(
                                                                referenceNumber:
                                                                refNumber,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(refNumber),
                                                  );
                                                },
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
