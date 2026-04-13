import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AmbulanceLocationService {
  static Timer? _timer;

  /// 🚑 START LIVE TRACKING (EVERY 5 SECONDS)
  static Future<void> startTracking(String ambulanceId) async {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return;
        }

        if (permission == LocationPermission.deniedForever) return;

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await FirebaseFirestore.instance
            .collection('ambulances')
            .doc(ambulanceId)
            .update({
          "lat": position.latitude,
          "lng": position.longitude,
          "updatedAt": FieldValue.serverTimestamp(),
        });

      } catch (e) {
        print("Location update error: $e");
      }
    });
  }

  /// 🛑 STOP TRACKING
  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }
}