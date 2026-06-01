import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomPath;
  final bool isDoctor;
  final int durationMinutes;
  final VoidCallback onCallEnd;

  // Required only on doctor side
  final String? clinicId;
  final String? appointmentId;
  final String? patientId;

  const VideoCallScreen({
    super.key,
    required this.roomPath,
    required this.isDoctor,
    required this.durationMinutes,
    required this.onCallEnd,
    this.clinicId,
    this.appointmentId,
    this.patientId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _service = WebRTCService();

  Timer? _timer;
  int _seconds = 0;

  bool _connected = false;
  bool _localMediaStarted = false;
  bool _isEnding = false;

  bool _observationSaved = false;
  bool _isSavingObservation = false;

  StreamSubscription<DocumentSnapshot>? _roomEndSubscription;
  bool _roomWasCreated = false;
  bool _remoteEndHandled = false;

  String _savedObservationText = '';
  String _savedPrescriptionText = '';

  @override
  void initState() {
    super.initState();
    _seconds = widget.durationMinutes * 60;

    // Patient side listener:
    // If doctor ends the call, patient screen will close automatically.
    _listenForDoctorCallEnd();

    initRTC();
  }

  void _listenForDoctorCallEnd() {
    // Only patient should listen for doctor ending the call.
    if (widget.isDoctor) return;

    _roomEndSubscription = FirebaseFirestore.instance
        .doc(widget.roomPath)
        .snapshots()
        .listen((snapshot) {
      if (_remoteEndHandled || _isEnding) return;

      if (snapshot.exists) {
        _roomWasCreated = true;

        final data = snapshot.data() as Map<String, dynamic>? ?? {};

        final bool doctorEnded =
            data['callEnded'] == true && data['endedBy'] == 'doctor';

        if (doctorEnded) {
          _handleDoctorEndedCall();
        }
      } else {
        // If room existed before and now it is deleted,
        // it means doctor ended/hangup deleted the room.
        if (_roomWasCreated || _connected) {
          _handleDoctorEndedCall();
        }
      }
    });
  }

  Future<void> _handleDoctorEndedCall() async {
    if (_remoteEndHandled || _isEnding) return;

    _remoteEndHandled = true;
    _isEnding = true;

    _timer?.cancel();
    await _roomEndSubscription?.cancel();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.call_end,
              color: Colors.redAccent,
              size: 42,
            ),
            SizedBox(height: 14),
            Text(
              "Call has been ended by doctor",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    try {
      await _service.hangUp(widget.roomPath);
    } catch (e) {
      debugPrint("Patient auto hangup error: $e");
    }

    if (!mounted) return;

    // Close the alert dialog.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Close the video call screen.
    if (Navigator.canPop(context)) {
      Navigator.pop(context, false);
    }
  }

  void initRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      await _service.openUserMedia(_localRenderer, _remoteRenderer);

      if (mounted) {
        setState(() => _localMediaStarted = true);
      }

      void onRemoteStream(MediaStream stream) {
        if (!mounted || _isEnding) return;

        setState(() => _connected = true);
        startTimer();
      }

      debugPrint("==================================");
      debugPrint("CALL ROLE: ${widget.isDoctor ? 'DOCTOR' : 'PATIENT'}");
      debugPrint("ROOM PATH: ${widget.roomPath}");
      debugPrint("DURATION MINUTES: ${widget.durationMinutes}");
      debugPrint("==================================");

      if (widget.isDoctor) {
        await _service.createRoom(
          widget.roomPath,
          _remoteRenderer,
          onRemoteStream: onRemoteStream,
        );
      } else {
        await _service.joinRoom(
          widget.roomPath,
          _remoteRenderer,
          onRemoteStream: onRemoteStream,
        );
      }

      _service.peerConnection?.onConnectionState = (state) {
        debugPrint("!!! WEB RTC STATE: $state");

        if (_isEnding || _remoteEndHandled) return;

        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (mounted) {
            setState(() => _connected = true);
            startTimer();
          }
        }

        if (!widget.isDoctor &&
            (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                state == RTCPeerConnectionState.RTCPeerConnectionStateClosed)) {
          _handleDoctorEndedCall();
        }
      };

      _service.peerConnection?.onAddStream = (stream) {
        if (_isEnding || _remoteEndHandled) return;

        _remoteRenderer.srcObject = stream;

        if (mounted) {
          setState(() => _connected = true);
          startTimer();
        }
      };
    } catch (e) {
      debugPrint("WebRTC Error: $e");
    }
  }

  void startTimer() {
    if (_timer != null || _isEnding || _remoteEndHandled) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isEnding || _remoteEndHandled) {
        t.cancel();
        return;
      }

      if (_seconds > 0) {
        if (mounted) {
          setState(() => _seconds--);
        }
      } else {
        _timer?.cancel();
        _timer = null;
        _endSession();
      }
    });
  }

  Future<void> _endSession() async {
    if (_isEnding) return;

    // Doctor cannot end call until observation is saved.
    // Prescription is optional.
    if (widget.isDoctor && !_observationSaved) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Observation is required before ending the call."),
          backgroundColor: Colors.redAccent,
        ),
      );

      _showObservationPrescriptionDialog();
      return;
    }

    _isEnding = true;
    _timer?.cancel();

    if (widget.isDoctor) {
      try {
        // Tell patient side that doctor has ended the call.
        await FirebaseFirestore.instance.doc(widget.roomPath).set(
          {
            'callEnded': true,
            'endedBy': 'doctor',
            'callEndedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Small delay so patient receives Firestore update
        // before the room is cleaned by hangUp().
        await Future.delayed(const Duration(milliseconds: 700));
      } catch (e) {
        debugPrint("Error marking call ended: $e");
      }
    }

    if (mounted) {
      Navigator.pop(context, widget.isDoctor);
    }

    try {
      await _service.hangUp(widget.roomPath);
    } catch (e) {
      debugPrint("Hangup error: $e");
    }

    if (widget.isDoctor) {
      widget.onCallEnd();
    }
  }

  Future<void> _saveObservationAndOptionalPrescription({
    required String observationText,
    required String prescriptionText,
  }) async {
    final patientId = widget.patientId;
    final appointmentId = widget.appointmentId;
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    if (patientId == null ||
        patientId.isEmpty ||
        appointmentId == null ||
        appointmentId.isEmpty ||
        doctorId == null) {
      throw Exception("Missing patient, appointment, or doctor information.");
    }

    final firestore = FirebaseFirestore.instance;
    final appointmentRef = firestore.doc(widget.roomPath);
    final now = FieldValue.serverTimestamp();

    final cleanObservation = observationText.trim();
    final cleanPrescription = prescriptionText.trim();

    final batch = firestore.batch();

    // 1. Save on appointment document temporarily.
    batch.set(
      appointmentRef,
      {
        'observationSaved': true,
        'observation': cleanObservation,
        'prescriptionText': cleanPrescription,
        'observationSavedAt': now,
      },
      SetOptions(merge: true),
    );

    // 2. Save observation permanently for later use.
    final observationHistoryRef = firestore
        .collection('patients')
        .doc(patientId)
        .collection('online_observations_history')
        .doc(appointmentId);

    batch.set(
      observationHistoryRef,
      {
        'doctorId': doctorId,
        'patientId': patientId,
        'clinicId': widget.clinicId,
        'appointmentId': appointmentId,
        'sourceAppointmentPath': widget.roomPath,
        'type': 'online',
        'observation': cleanObservation,
        'prescriptionText': cleanPrescription,
        'createdAt': now,
      },
      SetOptions(merge: true),
    );

    // 3. Save prescription only if doctor entered it.
    // Prescription is optional, so empty prescription will not create a prescription record.
    if (cleanPrescription.isNotEmpty) {
      final patientPrescriptionRef = firestore
          .collection('patients')
          .doc(patientId)
          .collection('prescriptions')
          .doc(appointmentId);

      batch.set(
        patientPrescriptionRef,
        {
          'doctorId': doctorId,
          'patientId': patientId,
          'clinicId': widget.clinicId,
          'appointmentId': appointmentId,
          'sourceAppointmentPath': widget.roomPath,
          'type': 'online',
          'createdAt': now,
          'prescriptionText': cleanPrescription,
          'prescriptionImageUrl': null,
          'observation': cleanObservation,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    // 4. Also update doctor_patient_history so you can use observation later
    // in patient profile/history screens.
    final historySnapshot = await firestore
        .collection('doctor_patient_history')
        .where('sourceAppointmentPath', isEqualTo: widget.roomPath)
        .limit(1)
        .get();

    for (final historyDoc in historySnapshot.docs) {
      await historyDoc.reference.set(
        {
          'observationSaved': true,
          'observation': cleanObservation,
          'prescriptionText': cleanPrescription,
          'observationSavedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  void _showObservationPrescriptionDialog() {
    if (!widget.isDoctor) return;

    final observationController =
    TextEditingController(text: _savedObservationText);
    final prescriptionController =
    TextEditingController(text: _savedPrescriptionText);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Observation & Prescription",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: observationController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Observation *",
                        hintText: "Enter doctor observation / diagnosis notes",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: prescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Prescription Optional",
                        hintText: "Enter medicine / dosage / advice if needed",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingObservation
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _isSavingObservation
                      ? null
                      : () async {
                    final observationText =
                    observationController.text.trim();
                    final prescriptionText =
                    prescriptionController.text.trim();

                    if (observationText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Observation is required."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    setDialogState(() => _isSavingObservation = true);

                    try {
                      await _saveObservationAndOptionalPrescription(
                        observationText: observationText,
                        prescriptionText: prescriptionText,
                      );

                      if (!mounted) return;

                      setState(() {
                        _observationSaved = true;
                        _isSavingObservation = false;
                        _savedObservationText = observationText;
                        _savedPrescriptionText = prescriptionText;
                      });

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Observation saved. You can now end the call.",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        _isSavingObservation = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Save failed: $e"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: _isSavingObservation
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roomEndSubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _connected
              ? RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white24),
                const SizedBox(height: 20),
                Text(
                  widget.isDoctor
                      ? "Waiting for patient..."
                      : "Connecting to doctor...",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Positioned(
            right: 20,
            top: 50,
            child: Container(
              width: 110,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _localMediaStarted
                    ? RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit:
                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
                    : const Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(child: _timerWidget()),
          ),

          if (widget.isDoctor)
            Positioned(
              bottom: 135,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _observationSaved ? Colors.green : Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSavingObservation
                    ? null
                    : _showObservationPrescriptionDialog,
                icon: Icon(
                  _observationSaved ? Icons.edit_note : Icons.note_add,
                  color: Colors.white,
                ),
                label: Text(
                  _observationSaved
                      ? "Edit Observation / Prescription"
                      : "Add Observation / Prescription",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: _endSession,
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerWidget() {
    int m = _seconds ~/ 60;
    int s = _seconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _seconds < 60 && _connected
            ? Colors.red.withOpacity(0.8)
            : Colors.black45,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _connected
            ? "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}"
            : "Initializing...",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}