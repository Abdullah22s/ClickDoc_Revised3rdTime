import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/doctor/doctor_current_patients_viewmodel.dart';
import 'doctor_patient_profile_view.dart';

class DoctorCurrentPatientsView extends StatelessWidget {
  // Theme Colors
  final Color primaryPurple = const Color(0xFF8B5CF6);
  final Color bgPurple = const Color(0xFFF5F3FF);
  final Color slate900 = const Color(0xFF0F172A);
  final Color slate600 = const Color(0xFF475569);

  const DoctorCurrentPatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorCurrentPatientsViewModel(),
      child: Consumer<DoctorCurrentPatientsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: Text(
                "Patient History",
                style: TextStyle(fontWeight: FontWeight.w800, color: slate900, letterSpacing: -0.5),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: slate900),
              actions: [
                IconButton(
                  icon: Icon(Icons.calendar_month_rounded, color: primaryPurple),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: vm.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) vm.updateDate(picked);
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildDateHeader(vm),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: vm.getPatientsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Grouping patients by Clinic/Department
                      final Map<String, List<QueryDocumentSnapshot>> groupedPatients = {};
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final clinicName = data['department'] ?? 'General Clinic';
                        if (!groupedPatients.containsKey(clinicName)) {
                          groupedPatients[clinicName] = [];
                        }
                        groupedPatients[clinicName]!.add(doc);
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedPatients.keys.length,
                        itemBuilder: (context, index) {
                          String clinicKey = groupedPatients.keys.elementAt(index);
                          List<QueryDocumentSnapshot> clinicPatients = groupedPatients[clinicKey]!;

                          return _buildClinicSection(context, clinicKey, clinicPatients);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DoctorCurrentPatientsViewModel vm) {
    bool isToday = DateFormat('yyyy-MM-dd').format(vm.selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 18, color: slate600),
          const SizedBox(width: 8),
          Text(
            isToday ? "Today's Schedule" : "Schedule for ${DateFormat('dd MMM yyyy').format(vm.selectedDate)}",
            style: TextStyle(fontWeight: FontWeight.w700, color: slate600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicSection(BuildContext context, String clinicName, List<QueryDocumentSnapshot> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: primaryPurple, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(
                clinicName.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w900, color: primaryPurple, fontSize: 13, letterSpacing: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                "(${patients.length})",
                style: TextStyle(color: slate600.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...patients.map((p) => _buildPatientCard(context, p)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPatientCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String reference = data['referenceNumber'] ?? 'N/A';
    final Timestamp? time = data['acceptedAt'] as Timestamp?;
    final String formattedTime = time != null ? DateFormat('hh:mm a').format(time.toDate()) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: bgPurple, borderRadius: BorderRadius.circular(15)),
          child: Center(
            child: Text(
              reference.isNotEmpty ? reference[0].toUpperCase() : "?",
              style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ),
        title: Text(
          "Ref: $reference",
          style: TextStyle(fontWeight: FontWeight.w800, color: slate900, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
            const SizedBox(width: 4),
            Text("Seen at $formattedTime", style: TextStyle(fontSize: 12, color: slate600, fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.chevron_right_rounded, color: primaryPurple),
        ),
        onTap: () async {
          String fetchedDoctorName = "Doctor";
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final docSnap = await FirebaseFirestore.instance.collection('doctors').doc(currentUser.uid).get();
            if (docSnap.exists) {
              fetchedDoctorName = docSnap.data()?['name'] ?? "Doctor";
            }
          }
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorPatientProfileView(
                referenceNumber: reference,
                doctorName: fetchedDoctorName,
              ),
            ),
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
          Icon(Icons.person_search_rounded, size: 64, color: slate600.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            "No patients found for this date.",
            style: TextStyle(color: slate600, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}