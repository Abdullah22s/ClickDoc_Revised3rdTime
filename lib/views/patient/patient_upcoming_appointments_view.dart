import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/patient/patient_upcoming_appointments_viewmodel.dart';
// ✅ NEW IMPORT
import '../shared/video_call_screen.dart';

class PatientUpcomingAppointmentsView extends StatelessWidget {
  const PatientUpcomingAppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientUpcomingAppointmentsViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Upcoming Online Appts", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer<PatientUpcomingAppointmentsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());
            if (vm.upcomingAppointments.isEmpty) return _buildEmptyState();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.upcomingAppointments.length,
              itemBuilder: (context, index) {
                final app = vm.upcomingAppointments[index];
                return _buildAppointmentCard(context, app, vm);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No appointments requiring vitals right now.",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text("Vitals entry opens 30 mins before session.",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> app, PatientUpcomingAppointmentsViewModel vm) {
    final bool vitalsEntered = app['vitalsEntered'] ?? false;
    final String status = app['status'] ?? 'accepted';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.videocam_rounded, color: Color(0xFFF97316)),
              ),
              title: Text("Dr. ${app['doctorName']}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              subtitle: Text("Time: ${app['start']} - ${app['end']}", style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),

            // --- DYNAMIC ACTIONS BASED ON STATUS ---
            if (status == 'in_progress') ...[
              const Text("Doctor has started the session!",
                  style: TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // ✅ UPDATED: JOIN VIDEO CALL
              _actionButton(
                label: "Join Session",
                color: const Color(0xFF10B981),
                icon: Icons.play_circle_fill,
                onTap: () async {
                  final appointmentRef = app['reference'] as DocumentReference;

                  int durationMinutes = 15;

                  try {
                    final clinicRef = appointmentRef.parent.parent;

                    if (clinicRef != null) {
                      final clinicSnapshot = await clinicRef.get();
                      final clinicData = clinicSnapshot.data() as Map<String, dynamic>?;

                      if (clinicData != null && clinicData['appointmentDuration'] != null) {
                        durationMinutes = clinicData['appointmentDuration'];
                      }
                    }
                  } catch (e) {
                    debugPrint("Error fetching appointment duration: $e");
                  }

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoCallScreen(
                        isDoctor: false,
                        roomPath: appointmentRef.path,
                        durationMinutes: durationMinutes,
                        onCallEnd: () {},
                      ),
                    ),
                  );
                },
              ),
            ] else if (vitalsEntered) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                  const SizedBox(width: 12),
                  const Text("Waiting for doctor to start the session...",
                      style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w700)),
                ],
              ),
            ] else ...[
              const Text("Please enter your current vitals to enable the session",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _actionButton(
                  label: "Enter Vitals",
                  color: const Color(0xFFF97316),
                  icon: Icons.monitor_heart,
                  onTap: () => _showVitalsEntry(context, vm, app['reference'])
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }

  void _showVitalsEntry(BuildContext context, PatientUpcomingAppointmentsViewModel vm, DocumentReference ref) {
    final bp = TextEditingController();
    final temp = TextEditingController();
    final spo2 = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Log My Vitals", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text("This data helps your doctor prepare for the session.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            _vitalInput("Blood Pressure", "e.g. 120/80", bp),
            _vitalInput("Temperature (°F)", "e.g. 98.6", temp),
            _vitalInput("SpO2 (%)", "e.g. 98", spo2),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              onPressed: vm.isSubmitting ? null : () async {
                final err = await vm.submitMyVitals(ref: ref, bp: bp.text, temp: temp.text, spo2: spo2.text);
                if (err == null) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Vitals submitted successfully!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: vm.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Vitals", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalInput(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}