import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/patient/patient_physical_opd_model.dart';

class BookPhysicalAppointmentView extends StatelessWidget {
  final String doctorId;
  final String opdId;
  final PhysicalOpdModel opd;

  BookPhysicalAppointmentView({
    super.key,
    required this.doctorId,
    required this.opdId,
    required this.opd
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> bookAppointment(Map<String, String> slot) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final patientDoc = await _firestore.collection('patients').doc(userId).get();
    if (!patientDoc.exists) throw Exception("Patient record not found");

    final referenceNumber = patientDoc.data()?['referenceNumber'] ?? 'N/A';

    final existingBooking = await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .doc(opdId)
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .get();

    if (existingBooking.docs.isNotEmpty) {
      throw Exception("You already have an appointment for this session");
    }

    final String? fcmToken = await FirebaseMessaging.instance.getToken();

    await _firestore
        .collection('doctors')
        .doc(doctorId)
        .collection('physical_opds')
        .doc(opdId)
        .collection('appointments')
        .add({
      'start': slot['start'],
      'end': slot['end'],
      'status': 'pending',
      'patientId': userId,
      'patientReference': referenceNumber,
      'patient_token': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book - ${opd.department}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hospital: ${opd.hospitalName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            Text("Department: ${opd.department}", style: const TextStyle(fontSize: 15)),
            Text("Time: ${opd.fromTime} - ${opd.toTime}", style: const TextStyle(fontSize: 15)),
            Text("Day: ${opd.day}", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            const Text("Available Slots", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: opd.slots.map((slot) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${slot['start']} - ${slot['end']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('doctors')
                                .doc(doctorId)
                                .collection('physical_opds')
                                .doc(opdId)
                                .collection('appointments')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();

                              final matching = snapshot.data!.docs.where((doc) =>
                              doc['start'] == slot['start'] &&
                                  doc['end'] == slot['end'] &&
                                  doc['status'] != 'rejected').toList();

                              if (matching.isEmpty) {
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                  onPressed: () async {
                                    try {
                                      await bookAppointment(slot);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Booking Request Sent")));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())));
                                    }
                                  },
                                  child: const Text("Book", style: TextStyle(color: Colors.white)),
                                );
                              }

                              // ✅ LOGIC UPDATED: Check for 'accepted' status
                              final data = matching.first.data() as Map<String, dynamic>;
                              final status = data['status'] ?? 'pending';

                              if (status == 'accepted' || status == 'in_progress') {
                                return const Text(
                                  "Accepted",
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                );
                              }

                              return const Text(
                                "Waiting for booking confirmation",
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}