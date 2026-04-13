import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AmbulanceDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get Ambulance Document ID using email
  Future<String?> getAmbulanceId(String email) async {
    try {
      final snapshot = await _firestore
          .collection('ambulances')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint("Error fetching ambulance ID: $e");
    }
    return null;
  }

  /// 🚨 STREAM ONLY NEARBY SOS REQUESTS
  Stream<QuerySnapshot> getSOSRequests(String ambulanceId) {
    return _firestore
        .collection('emergency_requests')
        .where('status', isEqualTo: 'pending')
        .where('nearbyAmbulances', arrayContains: ambulanceId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ ACCEPT REQUEST (STEP 5A FIX INCLUDED)
  Future<void> acceptRequest(String docId, String ambulanceEmail) async {
    try {
      await _firestore.collection('emergency_requests').doc(docId).update({
        "status": "accepted",
        "acceptedBy": ambulanceEmail,

        /// 🚑 STEP 5A FIX: lock ambulance to request
        "assignedAmbulance": ambulanceEmail,
        "acceptedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error accepting request: $e");
    }
  }

  /// ❌ REJECT REQUEST
  Future<void> rejectRequest(String docId) async {
    try {
      await _firestore.collection('emergency_requests').doc(docId).update({
        "status": "rejected",
      });
    } catch (e) {
      debugPrint("Error rejecting request: $e");
    }
  }
}