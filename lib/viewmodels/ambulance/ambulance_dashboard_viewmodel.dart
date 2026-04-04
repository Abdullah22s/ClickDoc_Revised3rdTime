import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AmbulanceDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getSOSRequests() {
    // Note: If results are empty, check your Debug Console for a 'Firebase Index' link.
    // Firestore needs a composite index for where('status') + orderBy('createdAt').
    return _firestore
        .collection('emergency_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> acceptRequest(String docId, String ambulanceEmail) async {
    try {
      await _firestore.collection('emergency_requests').doc(docId).update({
        "status": "accepted",
        "acceptedBy": ambulanceEmail,
      });
      // StreamBuilder handles the list update automatically
    } catch (e) {
      debugPrint("Error accepting request: $e");
    }
  }

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