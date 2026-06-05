import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class OperatorRegistrationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// Registers the operator in Firestore and returns true if successful
  Future<bool> registerOperator({
    required String name,
    required String email,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final docRef = await _firestore.collection('operators').add({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'operator',
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'active', // Default status
      });

      await NotificationService.saveTokenForRole(
        collection: 'operators',
        docId: docRef.id,
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Operator Registration Error: $e");
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}