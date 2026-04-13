import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AmbulanceTrackingScreen extends StatefulWidget {
  final String requestId;

  const AmbulanceTrackingScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<AmbulanceTrackingScreen> createState() =>
      _AmbulanceTrackingScreenState();
}

class _AmbulanceTrackingScreenState extends State<AmbulanceTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleMapController? _mapController;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _requestSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ambulanceSub;

  LatLng? patientLocation;
  LatLng? ambulanceLocation;

  Set<Marker> markers = {};

  bool _firstMoveDone = false;

  @override
  void initState() {
    super.initState();
    _listenToRequest();
  }

  /// 🚑 PATIENT LIVE STREAM
  void _listenToRequest() {
    _requestSub = _firestore
        .collection('emergency_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      final double lat = (data['lat'] ?? 0).toDouble();
      final double lng = (data['lng'] ?? 0).toDouble();

      final String? assignedAmbulance = data['acceptedBy'];

      _updatePatientMarker(lat, lng);

      if (assignedAmbulance != null) {
        _listenToAmbulance(assignedAmbulance);
      }
    });
  }

  /// 📍 UPDATE PATIENT MARKER
  void _updatePatientMarker(double lat, double lng) {
    patientLocation = LatLng(lat, lng);

    setState(() {
      markers.removeWhere((m) => m.markerId.value == "patient");

      markers.add(
        Marker(
          markerId: const MarkerId("patient"),
          position: patientLocation!,
          infoWindow: const InfoWindow(title: "Patient"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    });
  }

  /// 🚑 AMBULANCE LIVE STREAM (REAL-TIME)
  void _listenToAmbulance(String ambulanceEmail) {
    _ambulanceSub?.cancel();

    _ambulanceSub = _firestore
        .collection('ambulances')
        .where('email', isEqualTo: ambulanceEmail)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final data = snapshot.docs.first.data();

      final double lat = (data['lat'] ?? 0).toDouble();
      final double lng = (data['lng'] ?? 0).toDouble();

      ambulanceLocation = LatLng(lat, lng);

      _updateAmbulanceMarker();

      /// 🚀 AUTO CAMERA FOLLOW (UBER STYLE)
      _moveCameraSmoothly();
    });
  }

  /// 🚑 UPDATE AMBULANCE MARKER
  void _updateAmbulanceMarker() {
    setState(() {
      markers.removeWhere((m) => m.markerId.value == "ambulance");

      markers.add(
        Marker(
          markerId: const MarkerId("ambulance"),
          position: ambulanceLocation!,
          infoWindow: const InfoWindow(title: "Ambulance 🚑"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    });
  }

  /// 🎯 UBER-LIKE CAMERA FOLLOW
  void _moveCameraSmoothly() {
    if (_mapController == null || ambulanceLocation == null) return;

    if (!_firstMoveDone) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(ambulanceLocation!, 16),
      );
      _firstMoveDone = true;
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(ambulanceLocation!),
      );
    }
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _ambulanceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Ambulance Tracking 🚑"),
        backgroundColor: Colors.redAccent,
      ),
      body: patientLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: patientLocation!,
          zoom: 14,
        ),
        markers: markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}