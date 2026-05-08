import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/doctor/doctor_appointments_viewmodel.dart';
import 'doctor_patient_profile_view.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  // Using a consistent color palette from your Dashboard theme
  final Color primaryOrange = const Color(0xFFF97316);
  final Color bgOrange = const Color(0xFFFFF7ED);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate600 = const Color(0xFF475569);

  DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: If you are using Provider in your main.dart for this ViewModel,
    // you can use context.watch. Otherwise, keeping your AnimatedBuilder logic.
    final viewModel = DoctorAppointmentsViewModel();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Dashboard Background
      appBar: AppBar(
        title: Text(
          "Online Appointments",
          style: TextStyle(fontWeight: FontWeight.w800, color: slate900, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: slate900),
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.appointments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.appointments.length,
            itemBuilder: (context, index) {
              final clinic = viewModel.appointments[index];

              // 🔹 Side logic: Delete past clinics automatically
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

              return _buildClinicCard(context, clinic, index, viewModel);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: slate600.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "No online clinics found.",
            style: TextStyle(color: slate600, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, dynamic clinic, int index, DoctorAppointmentsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of the Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgOrange,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryOrange,
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clinic Session #${index + 1}",
                        style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 16),
                      ),
                      Text(
                        "${clinic.days.join(', ')} • ${clinic.startTime} - ${clinic.endTime}",
                        style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Rs ${clinic.fees}",
                  style: TextStyle(fontWeight: FontWeight.w900, color: slate900, fontSize: 16),
                ),
              ],
            ),
          ),

          // Slots List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Booking Requests",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                ...clinic.slots.map((slot) => _buildSlotItem(context, clinic, slot, viewModel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(BuildContext context, dynamic clinic, dynamic slot, DoctorAppointmentsViewModel viewModel) {
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
          return data['start'] == slot.start && data['end'] == slot.end;
        }).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Light slate
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    "${slot.start} - ${slot.end}",
                    style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 13),
                  ),
                  const Spacer(),
                  if (requests.isEmpty)
                    const Text("Available", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              if (requests.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...requests.map((requestDoc) => _buildRequestActions(context, clinic, requestDoc, viewModel)),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestActions(BuildContext context, dynamic clinic, DocumentSnapshot requestDoc, DoctorAppointmentsViewModel viewModel) {
    final data = requestDoc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final patientId = data['patientId'] ?? '';

    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: _smallButton(
              label: "Accept",
              color: const Color(0xFF10B981), // Emerald Green
              onTap: () async {
                final smsSent = await viewModel.handleAppointment(
                  clinicId: clinic.id,
                  appointmentId: requestDoc.id,
                  action: 'accept',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(smsSent ? "Accepted & SMS sent." : "Accepted, SMS failed."),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _smallButton(
              label: "Reject",
              color: const Color(0xFFEF4444), // Red
              onTap: () => viewModel.handleAppointment(
                clinicId: clinic.id,
                appointmentId: requestDoc.id,
                action: 'reject',
              ),
            ),
          ),
        ],
        if (status != 'pending') ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: status == 'accepted' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'accepted' ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        if (patientId.isNotEmpty)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
            builder: (context, snapshot) {
              String refNumber = '...';
              if (snapshot.hasData && snapshot.data!.exists) {
                refNumber = (snapshot.data!.data() as Map<String, dynamic>)['referenceNumber'] ?? 'N/A';
              }
              return Expanded(
                child: _smallButton(
                  label: refNumber,
                  color: primaryOrange, // Theme color
                  onTap: () async {
                    String fetchedDoctorName = "Doctor";
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      final docSnap = await FirebaseFirestore.instance.collection('doctors').doc(currentUser.uid).get();
                      if (docSnap.exists) {
                        fetchedDoctorName = (docSnap.data() as Map<String, dynamic>)['name'] ?? "Doctor";
                      }
                    }
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorPatientProfileView(
                          referenceNumber: refNumber,
                          doctorName: fetchedDoctorName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _smallButton({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}