import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor/doctor_dashboard_model.dart';

class TrendingObservation {
  final String observation;
  final int count;
  final int totalObservations;

  TrendingObservation({
    required this.observation,
    required this.count,
    required this.totalObservations,
  });
}

class DoctorDashboardViewModel extends ChangeNotifier {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DoctorDashboardViewModel({
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  List<DoctorDashboardModel> get dashboardItems => [
    DoctorDashboardModel(icon: Icons.person, label: 'Profile'),
    DoctorDashboardModel(icon: Icons.videocam_rounded, label: 'Online Appointments'),
    DoctorDashboardModel(icon: Icons.assignment_ind_rounded, label: 'Physical Requests'),
    DoctorDashboardModel(icon: Icons.local_hospital_rounded, label: 'Physical OPD'),
    DoctorDashboardModel(icon: Icons.medical_services_rounded, label: 'Online Clinic'),
    DoctorDashboardModel(icon: Icons.people_alt_rounded, label: 'Current Patients'),
  ];

  Future<TrendingObservation?> getTrendingObservationLast7Days() async {
    try {
      final doctorId = FirebaseAuth.instance.currentUser?.uid;

      if (doctorId == null || doctorId.isEmpty) {
        debugPrint("Doctor ID not found.");
        return null;
      }

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collectionGroup('online_observations_history')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final Map<String, int> observationCount = {};
      final Map<String, String> originalObservationText = {};

      int totalObservations = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final createdAt = data['createdAt'];
        DateTime? createdDate;

        if (createdAt is Timestamp) {
          createdDate = createdAt.toDate();
        } else if (createdAt is DateTime) {
          createdDate = createdAt;
        }

        if (createdDate == null) continue;

        if (createdDate.isBefore(sevenDaysAgo)) continue;

        final observation = (data['observation'] ?? '').toString().trim();

        if (observation.isEmpty) continue;

        final key = observation.toLowerCase();

        observationCount[key] = (observationCount[key] ?? 0) + 1;
        originalObservationText[key] = observation;

        totalObservations++;
      }

      if (observationCount.isEmpty) {
        return null;
      }

      final sortedEntries = observationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topObservation = sortedEntries.first;

      return TrendingObservation(
        observation: originalObservationText[topObservation.key] ?? topObservation.key,
        count: topObservation.value,
        totalObservations: totalObservations,
      );
    } catch (e) {
      debugPrint("Error getting trending observation: $e");
      return null;
    }
  }
}