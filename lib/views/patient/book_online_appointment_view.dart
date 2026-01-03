import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';

class BookOnlineAppointmentView extends StatelessWidget {
  final DoctorOnlineClinicModel clinic;

  BookOnlineAppointmentView({super.key, required this.clinic});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔒 MAIN BOOKING FUNCTION
  Future<void> bookAppointment(AppointmentSlot slot) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // 1️⃣ Get patient reference number
    final patientDoc =
    await _firestore.collection('patients').doc(userId).get();

    if (!patientDoc.exists) {
      throw Exception("Patient record not found");
    }

    final referenceNumber =
        patientDoc.data()?['referenceNumber'] ?? 'N/A';

    // 2️⃣ Prevent patient booking more than ONE slot in this clinic
    final existingPatientBooking = await _firestore
        .collection('doctors')
        .doc(clinic.doctorId)
        .collection('online_clinics')
        .doc(clinic.id)
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();

    if (existingPatientBooking.docs.isNotEmpty) {
      throw Exception("You already booked a slot in this clinic");
    }

    // 3️⃣ Prevent double booking of same slot
    final existingSlotBooking = await _firestore
        .collection('doctors')
        .doc(clinic.doctorId)
        .collection('online_clinics')
        .doc(clinic.id)
        .collection('appointments')
        .where('start', isEqualTo: slot.start)
        .where('end', isEqualTo: slot.end)
        .where('status', whereIn: ['pending', 'accepted'])
        .get();

    if (existingSlotBooking.docs.isNotEmpty) {
      throw Exception("This slot is already booked");
    }

    // 🔔 GET PATIENT FCM TOKEN
    final String? fcmToken =
    await FirebaseMessaging.instance.getToken();

    // 4️⃣ Create appointment
    await _firestore
        .collection('doctors')
        .doc(clinic.doctorId)
        .collection('online_clinics')
        .doc(clinic.id)
        .collection('appointments')
        .add({
      'start': slot.start,
      'end': slot.end,
      'status': 'pending',
      'patientId': userId,
      'patientReference': referenceNumber,

      // ✅ MUST MATCH PYTHON SCRIPT
      'patient_token': fcmToken,
      'notified': false,
      'reminder_sent': false,

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment - ${clinic.department}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Department: ${clinic.department}"),
            Text("Time: ${clinic.startTime} - ${clinic.endTime}"),
            Text("Days: ${clinic.days.join(', ')}"),
            Text("Fees: PKR ${clinic.fees}"),
            const SizedBox(height: 16),
            const Text(
              "Available Slots",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            /// 🔁 SLOT LIST
            Expanded(
              child: ListView(
                children: clinic.slots.map((slot) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${slot.start} - ${slot.end}"),

                          /// 🔥 REAL-TIME SLOT STATE
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('doctors')
                                .doc(clinic.doctorId)
                                .collection('online_clinics')
                                .doc(clinic.id)
                                .collection('appointments')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                );
                              }

                              final matching =
                              snapshot.data!.docs.where((doc) {
                                final data =
                                doc.data() as Map<String, dynamic>;
                                return data['start'] == slot.start &&
                                    data['end'] == slot.end &&
                                    (data['status'] == 'pending' ||
                                        data['status'] ==
                                            'accepted');
                              }).toList();

                              if (matching.isEmpty) {
                                return ElevatedButton(
                                  child: const Text("Book"),
                                  onPressed: () async {
                                    try {
                                      await bookAppointment(slot);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Appointment requested"),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                          Text(e.toString()),
                                        ),
                                      );
                                    }
                                  },
                                );
                              }

                              final status =
                              (matching.first.data()
                              as Map<String, dynamic>)['status'];

                              if (status == 'pending') {
                                return const Text(
                                  "Booking in progress",
                                  style: TextStyle(
                                      color: Colors.orange),
                                );
                              }

                              return const Text(
                                "Booked",
                                style:
                                TextStyle(color: Colors.red),
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
