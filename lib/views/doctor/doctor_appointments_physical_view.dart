import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/doctor/doctor_appointments_physical_viewmodel.dart';
import '../../models/doctor/doctor_online_clinic_model.dart';
import 'doctor_patient_profile_view.dart';

class DoctorPhysicalAppointmentsScreen extends StatelessWidget {
  final Color primaryOrange = const Color(0xFFF97316);
  final Color bgOrange = const Color(0xFFFFF7ED);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate600 = const Color(0xFF475569);

  const DoctorPhysicalAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = DoctorPhysicalAppointmentsViewModel();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Physical Appointments", style: TextStyle(fontWeight: FontWeight.w800, color: slate900, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: slate900),
      ),
      body: AnimatedBuilder(
        animation: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
          if (viewModel.appointments.isEmpty) return _buildEmptyState();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.appointments.length,
            itemBuilder: (context, index) {
              final clinic = viewModel.appointments[index];
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
          Text("No physical clinics found.", style: TextStyle(color: slate600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, PhysicalClinicModel clinic, int index, DoctorPhysicalAppointmentsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryOrange.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bgOrange, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: primaryOrange, child: const Icon(Icons.location_on, color: Colors.white, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clinic.hospitalName, style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 16)),
                      Text("${clinic.days.join(', ')} • ${clinic.startTime} - ${clinic.endTime}", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                Text("Rs ${clinic.fees}", style: TextStyle(fontWeight: FontWeight.w900, color: slate900, fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Booking Requests", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                ...clinic.slots.map((slot) => _buildSlotItem(context, clinic, slot, viewModel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotItem(BuildContext context, PhysicalClinicModel clinic, AppointmentSlot slot, DoctorPhysicalAppointmentsViewModel viewModel) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('physical_opds')
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
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text("${slot.start} - ${slot.end}", style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 13)),
                  const Spacer(),
                  if (requests.isEmpty) const Text("Available", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              if (requests.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...requests.map((requestDoc) => _buildRequestActions(context, clinic, requestDoc, viewModel)),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestActions(BuildContext context, PhysicalClinicModel clinic, DocumentSnapshot requestDoc, DoctorPhysicalAppointmentsViewModel viewModel) {
    final data = requestDoc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final vitalsEntered = data['vitalsEntered'] ?? false;
    final patientId = data['patientId'] ?? '';

    return Column(
      children: [
        Row(
          children: [
            if (status == 'pending') ...[
              Expanded(child: _actionBtn(label: "Accept", color: const Color(0xFF10B981), onTap: () => viewModel.handleAppointment(clinicId: clinic.id, appointmentId: requestDoc.id, action: 'accept'))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn(label: "Reject", color: const Color(0xFFEF4444), onTap: () => viewModel.handleAppointment(clinicId: clinic.id, appointmentId: requestDoc.id, action: 'reject'))),
            ],
            if (status == 'accepted' && !vitalsEntered) ...[
              Expanded(child: _actionBtn(label: "Waiting for Vitals...", color: Colors.grey.shade400, onTap: () {})),
            ],
            if (status == 'accepted' && vitalsEntered) ...[
              Expanded(child: _actionBtn(label: "Check Vitals", color: const Color(0xFF3B82F6), onTap: () => _showVitalsDialog(context, data['vitals']))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn(label: "Start Appt", color: const Color(0xFF10B981), onTap: () => viewModel.startAppointment(clinic.id, requestDoc.id))),
            ],
            if (status == 'in_progress') ...[
              Expanded(child: _actionBtn(label: "End Appointment", color: const Color(0xFFEF4444), onTap: () => {})), // Add your end appointment logic dialog
            ],
            if (patientId.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildPatientProfileButton(context, patientId),
            ]
          ],
        ),
      ],
    );
  }

  // Action Button, Patient Profile Button, Vitals Dialog helpers are identical to your Online View code
  // ... [Keep the same helper methods from your Online View here]

  Widget _actionBtn({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center)),
      ),
    );
  }

  Widget _buildPatientProfileButton(BuildContext context, String patientId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
      builder: (context, snapshot) {
        String refNumber = '...';
        if (snapshot.hasData && snapshot.data!.exists) {
          refNumber = (snapshot.data!.data() as Map<String, dynamic>)['referenceNumber'] ?? 'N/A';
        }
        return Expanded(
          flex: 0,
          child: _actionBtn(
            label: refNumber,
            color: primaryOrange,
            onTap: () async {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientProfileView(referenceNumber: refNumber, doctorName: "Doctor")));
            },
          ),
        );
      },
    );
  }

  void _showVitalsDialog(BuildContext context, dynamic vitalsData) {
    final vitals = vitalsData as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Patient Vitals", style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _vitalRow(Icons.bloodtype, "BP", vitals?['bp'] ?? 'N/A'),
            _vitalRow(Icons.thermostat, "Temp", vitals?['temp'] ?? 'N/A'),
            _vitalRow(Icons.air, "SpO2", vitals?['spo2'] ?? 'N/A'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  Widget _vitalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, size: 20, color: slate600), const SizedBox(width: 8), Text(label)]),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: slate900)),
        ],
      ),
    );
  }
}