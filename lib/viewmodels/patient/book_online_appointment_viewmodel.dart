import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ ADDED

class BookOnlineAppointmentViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isBooking = false;

  Future<void> bookAppointment({
    required String doctorId,
    required String clinicId,
    required String doctorName,
    required String department,
    required String slotStart,
    required String slotEnd,
    required int fees,
    required String patientId,
  }) async {
    try {
      isBooking = true;
      notifyListeners();

      // 🔐 Prevent double booking of same slot
      final existing = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('slotStart', isEqualTo: slotStart)
          .where('slotEnd', isEqualTo: slotEnd)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('This slot is already booked');
      }

      // 🔔 GET PATIENT FCM TOKEN (✅ ADDED)
      final String? fcmToken =
      await FirebaseMessaging.instance.getToken();

      await _firestore.collection('appointments').add({
        'doctorId': doctorId,
        'clinicId': clinicId,
        'doctorName': doctorName,
        'patientId': patientId,
        'department': department,
        'slotStart': slotStart,
        'slotEnd': slotEnd,
        'fees': fees,
        'clinicType': 'online',

        // 🔔 NOTIFICATION FIELDS (✅ ADDED)
        'patientFcmToken': fcmToken,
        'statusNotified': false,
        'reminder24hSent': false,

        'status': 'pending', // doctor will accept later
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      isBooking = false;
      notifyListeners();
    }
  }
}
