import 'package:flutter/material.dart';
import '../../viewmodels/doctor/doctor_appointments_viewmodel.dart';


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

          final appointments = viewModel.appointments;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("Days: ${appointment.days.join(', ')}"),
                      Text("Time: ${appointment.startTime} - ${appointment.endTime}"),
                      Text("Fees: Rs ${appointment.fees}"),
                      Text("Appointment Duration: ${appointment.appointmentDuration} min"),
                      Text("Buffer: ${appointment.bufferDuration} min"),
                      const SizedBox(height: 10),
                      const Text(
                        "Slots:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...appointment.slots.map((slot) => Text(
                        "• ${slot.start} - ${slot.end}",
                        style: const TextStyle(fontSize: 14),
                      )),
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
