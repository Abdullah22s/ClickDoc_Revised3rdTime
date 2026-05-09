import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/Operator/operator_dashboard_viewmodel.dart';

class OperatorDashboardScreen extends StatefulWidget {
  final String operatorEmail;

  const OperatorDashboardScreen({super.key, required this.operatorEmail});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> {
  // Orange Theme for Operator
  final Color primaryOrange = const Color(0xFFE65100);
  final Color slate900 = const Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OperatorDashboardViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            "Vitals Queue",
            style: TextStyle(fontWeight: FontWeight.w800, color: slate900),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            )
          ],
        ),
        body: Consumer<OperatorDashboardViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return Center(child: CircularProgressIndicator(color: primaryOrange));
            }

            if (vm.visibleAppointments.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: vm.visibleAppointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(context, vm.visibleAppointments[index], vm);
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
          Icon(Icons.monitor_heart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Queue is empty",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Patients appear here 30 mins before their scheduled start time.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> app, OperatorDashboardViewModel vm) {
    // ✅ Logic to handle nested time strings from slots if top-level 'start' is missing
    final String timeDisplay = app['start'] ??
        (app['slots'] != null && (app['slots'] as List).isNotEmpty
            ? app['slots'][0]['start']
            : '--:--');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primaryOrange.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primaryOrange.withOpacity(0.1),
                child: Icon(Icons.person, color: primaryOrange),
              ),
              title: Text(
                app['patientName'] ?? 'Unknown Patient',
                style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 17),
              ),
              subtitle: Text(
                "Dr. ${app['doctorName']}\nSlot: $timeDisplay",
                style: const TextStyle(height: 1.5),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeDisplay,
                  style: TextStyle(fontWeight: FontWeight.w700, color: slate900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showVitalsBottomSheet(
                    context,
                    vm,
                    app['appointmentRef'] as DocumentReference
                ),
                child: const Text(
                  "Collect Vitals",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showVitalsBottomSheet(BuildContext context, OperatorDashboardViewModel vm, DocumentReference appointmentRef) {
    final bpController = TextEditingController();
    final tempController = TextEditingController();
    final spo2Controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Log Patient Vitals",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            _vitalTextField("Blood Pressure", "e.g. 120/80", bpController),
            const SizedBox(height: 12),
            _vitalTextField("Temperature (°F)", "e.g. 98.6", tempController),
            const SizedBox(height: 12),
            _vitalTextField("SpO2 (%)", "e.g. 98", spo2Controller),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: vm.isSubmitting ? null : () async {
                  final error = await vm.submitVitals(
                    appointmentRef: appointmentRef,
                    bp: bpController.text,
                    temp: tempController.text,
                    spo2: spo2Controller.text,
                  );

                  if (!bottomSheetContext.mounted) return;

                  if (error != null) {
                    ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red)
                    );
                  } else {
                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vitals saved!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        )
                    );
                  }
                },
                child: vm.isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                    "Save Vitals",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _vitalTextField(String label, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryOrange, width: 2),
        ),
      ),
    );
  }
}