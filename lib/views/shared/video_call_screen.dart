import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomPath;
  final bool isDoctor;
  final int durationMinutes;
  final VoidCallback onCallEnd;

  const VideoCallScreen({
    super.key,
    required this.roomPath,
    required this.isDoctor,
    required this.durationMinutes,
    required this.onCallEnd,
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

  @override
  void initState() {
    super.initState();
    _seconds = widget.durationMinutes * 60;
    initRTC();
  }

  void initRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      await _service.openUserMedia(_localRenderer, _remoteRenderer);
      if (mounted) setState(() => _localMediaStarted = true);

      void onRemoteStream(MediaStream stream) {
        if (!mounted) return;

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

      // Explicitly monitor the state of the peerConnection
      _service.peerConnection?.onConnectionState = (state) {
        debugPrint("!!! WEB RTC STATE: $state");
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (mounted) {
            setState(() => _connected = true);
            startTimer();
          }
        }
      };

      // Backup: Some devices trigger onAddStream instead of onTrack
      _service.peerConnection?.onAddStream = (stream) {
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
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        if (mounted) setState(() => _seconds--);
      } else {
        _endSession();
      }
    });
  }

  Future<void> _endSession() async {
    if (_isEnding) return;
    _isEnding = true;

    _timer?.cancel();

    if (mounted) {
      Navigator.pop(context, widget.isDoctor);
    }

    await _service.hangUp(widget.roomPath);

    if (widget.isDoctor) {
      widget.onCallEnd();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white24),
                const SizedBox(height: 20),
                Text(widget.isDoctor ? "Waiting for patient..." : "Connecting to doctor...",
                    style: const TextStyle(color: Colors.white70)),
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
                    ? RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                    : const Center(child: Icon(Icons.videocam_off, color: Colors.white24)),
              ),
            ),
          ),
          Positioned(top: 60, left: 0, right: 0, child: Center(child: _timerWidget())),
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
                  child: const Icon(Icons.call_end, color: Colors.white, size: 30),
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
        color: _seconds < 60 && _connected ? Colors.red.withOpacity(0.8) : Colors.black45,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _connected
            ? "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}"
            : "Initializing...",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}