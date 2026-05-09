import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for date formatting
import '../../viewmodels/Operator/operator_dashboard_viewmodel.dart';

class OperatorDashboardScreen extends StatelessWidget {
  final String operatorEmail;
  final Color primaryOrange = const Color(0xFFE65100);
  final Color slate900 = const Color(0xFF0F172A);

  const OperatorDashboardScreen({super.key, required this.operatorEmail});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OperatorDashboardViewModel(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text("Operator Dashboard", style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: TabBar(
              labelColor: primaryOrange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryOrange,
              tabs: const [
                Tab(text: "Current Queue"),
                Tab(text: "Past Patients"),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              )
            ],
          ),
          body: Consumer<OperatorDashboardViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) return const Center(child: CircularProgressIndicator());

              return TabBarView(
                children: [
                  // Tab 1: Current Queue
                  _buildList(context, vm.currentAppointments, vm, isPast: false),

                  // Tab 2: Past Patients (with Date Filter)
                  Column(
                    children: [
                      _buildDateHeader(context, vm),
                      Expanded(child: _buildList(context, vm.pastAppointments, vm, isPast: true)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, OperatorDashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Records for: ${DateFormat('dd MMM, yyyy').format(vm.selectedDate)}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          TextButton.icon(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: vm.selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) vm.updateSelectedDate(picked);
            },
            icon: Icon(Icons.calendar_month, size: 18, color: primaryOrange),
            label: Text("Change Date", style: TextStyle(color: primaryOrange)),
          )
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> list, OperatorDashboardViewModel vm, {required bool isPast}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPast ? Icons.history : Icons.monitor_heart_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(isPast ? "No records found for this date" : "Queue is empty",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildAppointmentCard(context, list[index], vm, isPast),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, dynamic> app, OperatorDashboardViewModel vm, bool isPast) {
    final String timeDisplay = app['start'] ?? '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPast ? Border.all(color: Colors.green.withOpacity(0.2)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(app['patientName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Dr. ${app['doctorName']}\nSlot: $timeDisplay"),
        trailing: isPast
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
          onPressed: () => _showVitalsBottomSheet(context, vm, app['appointmentRef']),
          child: const Text("Collect", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // ... (Keep _showVitalsBottomSheet and _vitalTextField exactly as they were before) ...

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