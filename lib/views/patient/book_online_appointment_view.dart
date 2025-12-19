import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';

class BookOnlineAppointmentView extends StatelessWidget {
  final DoctorOnlineClinicModel clinic;

  BookOnlineAppointmentView({super.key, required this.clinic});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> bookAppointment(AppointmentSlot slot) async {
    try {
      final appointmentData = {
        'start': slot.start,
        'end': slot.end,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('doctors')
          .doc(clinic.doctorId)
          .collection('online_clinics')
          .doc(clinic.id)
          .collection('appointments')
          .add(appointmentData);
    } catch (e) {
      print("Error booking appointment: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment - ${clinic.department}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Department: ${clinic.department}"),
            Text("Time: ${clinic.startTime} - ${clinic.endTime}"),
            Text("Days: ${clinic.days.join(', ')}"),
            Text("Fees: PKR ${clinic.fees}"),
            const SizedBox(height: 16),
            const Text("Available Slots:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...clinic.slots.map(
                  (slot) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${slot.start} - ${slot.end}"),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await bookAppointment(slot);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Appointment requested successfully")),
                          );
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to book appointment")),
                          );
                        }
                      },
                      child: const Text("Book"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
