import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  StreamSubscription? _roomSub;
  StreamSubscription? _callerSub;
  StreamSubscription? _calleeSub;

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:global.stun.twilio.com:3478'},

      // For production, add TURN server here.
      // {
      //   'urls': 'turn:your-turn-server.com:3478',
      //   'username': 'username',
      //   'credential': 'password',
      // },
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> openUserMedia(
      RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo,
      ) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
      'audio': true,
    });

    localVideo.srcObject = stream;
    localStream = stream;
  }

  Future<void> _createPeerConnection(
      RTCVideoRenderer remoteVideo, {
        void Function(MediaStream stream)? onRemoteStream,
      }) async {
    peerConnection = await createPeerConnection(configuration);

    for (final track in localStream?.getTracks() ?? []) {
      await peerConnection?.addTrack(track, localStream!);
    }

    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('REMOTE TRACK RECEIVED');

      if (event.streams.isNotEmpty) {
        remoteVideo.srcObject = event.streams[0];
        onRemoteStream?.call(event.streams[0]);
      }
    };

    peerConnection?.onConnectionState = (state) {
      print('WEBRTC CONNECTION STATE: $state');
    };

    peerConnection?.onIceConnectionState = (state) {
      print('WEBRTC ICE STATE: $state');
    };

    peerConnection?.onIceGatheringState = (state) {
      print('WEBRTC ICE GATHERING STATE: $state');
    };
  }

  Future<void> _clearCollection(
      CollectionReference<Map<String, dynamic>> collection,
      ) async {
    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  RTCIceCandidate _candidateFromMap(Map<String, dynamic> data) {
    return RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
  }

  Future<void> createRoom(
      String roomPath,
      RTCVideoRenderer remoteVideo, {
        void Function(MediaStream stream)? onRemoteStream,
      }) async {
    print('DOCTOR CREATING ROOM AT: $roomPath');

    final roomRef = _firestore.doc(roomPath);

    await roomRef.set({
      'offer': null,
      'answer': null,
    }, SetOptions(merge: true));

    await _clearCollection(roomRef.collection('callerCandidates'));
    await _clearCollection(roomRef.collection('calleeCandidates'));

    await _createPeerConnection(
      remoteVideo,
      onRemoteStream: onRemoteStream,
    );

    final callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (candidate) async {
      if (candidate.candidate != null) {
        print('DOCTOR ICE CANDIDATE ADDED');
        await callerCandidatesCollection.add(candidate.toMap());
      }
    };

    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    await roomRef.set({
      'offer': offer.toMap(),
      'answer': null,
    }, SetOptions(merge: true));

    print('DOCTOR OFFER CREATED');

    bool answerSet = false;

    _roomSub = roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();

      if (data == null) return;
      if (answerSet) return;
      if (data['answer'] == null) return;

      answerSet = true;

      final answerData = data['answer'];

      final answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );

      await peerConnection?.setRemoteDescription(answer);

      print('DOCTOR RECEIVED ANSWER');

      _calleeSub ??= roomRef.collection('calleeCandidates').snapshots().listen(
            (snapshot) async {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final candidateData = change.doc.data();

              if (candidateData != null && candidateData['candidate'] != null) {
                print('DOCTOR RECEIVED CALLEE CANDIDATE');

                await peerConnection?.addCandidate(
                  _candidateFromMap(candidateData),
                );
              }
            }
          }
        },
      );
    });
  }

  Future<void> joinRoom(
      String roomPath,
      RTCVideoRenderer remoteVideo, {
        void Function(MediaStream stream)? onRemoteStream,
      }) async {
    print('PATIENT JOINING ROOM AT: $roomPath');

    final roomRef = _firestore.doc(roomPath);

    await _createPeerConnection(
      remoteVideo,
      onRemoteStream: onRemoteStream,
    );

    final calleeCandidatesCollection = roomRef.collection('calleeCandidates');

    peerConnection?.onIceCandidate = (candidate) async {
      if (candidate.candidate != null) {
        print('PATIENT ICE CANDIDATE ADDED');
        await calleeCandidatesCollection.add(candidate.toMap());
      }
    };

    bool answered = false;

    Future<void> answerOffer(Map<String, dynamic> data) async {
      if (answered) return;
      if (data['offer'] == null) return;

      answered = true;

      final offerData = data['offer'];

      final offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );

      await peerConnection?.setRemoteDescription(offer);

      print('PATIENT RECEIVED OFFER');

      final answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      await roomRef.set({
        'answer': answer.toMap(),
      }, SetOptions(merge: true));

      print('PATIENT ANSWER CREATED');

      _callerSub ??= roomRef.collection('callerCandidates').snapshots().listen(
            (snapshot) async {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final candidateData = change.doc.data();

              if (candidateData != null && candidateData['candidate'] != null) {
                print('PATIENT RECEIVED CALLER CANDIDATE');

                await peerConnection?.addCandidate(
                  _candidateFromMap(candidateData),
                );
              }
            }
          }
        },
      );
    }

    final roomSnapshot = await roomRef.get();
    final roomData = roomSnapshot.data();

    if (roomData != null && roomData['offer'] != null) {
      await answerOffer(roomData);
    } else {
      print('PATIENT WAITING FOR DOCTOR OFFER');

      _roomSub = roomRef.snapshots().listen((snapshot) async {
        final data = snapshot.data();

        if (data != null && data['offer'] != null) {
          await _roomSub?.cancel();
          _roomSub = null;

          await answerOffer(data);
        }
      });
    }
  }

  Future<void> hangUp(String roomPath) async {
    await _roomSub?.cancel();
    await _callerSub?.cancel();
    await _calleeSub?.cancel();

    _roomSub = null;
    _callerSub = null;
    _calleeSub = null;

    for (final track in localStream?.getTracks() ?? []) {
      await track.stop();
    }

    await peerConnection?.close();
    peerConnection = null;

    try {
      final roomRef = _firestore.doc(roomPath);

      await roomRef.update({
        'offer': null,
        'answer': null,
      });
    } catch (_) {}
  }
}