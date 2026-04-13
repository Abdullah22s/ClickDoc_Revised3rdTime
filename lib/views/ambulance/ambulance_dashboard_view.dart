import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/ambulance/ambulance_dashboard_viewmodel.dart';

class AmbulanceDashboardScreen extends StatefulWidget {
  final String ambulanceEmail;

  const AmbulanceDashboardScreen({
    super.key,
    required this.ambulanceEmail,
  });

  @override
  State<AmbulanceDashboardScreen> createState() =>
      _AmbulanceDashboardScreenState();
}

class _AmbulanceDashboardScreenState
    extends State<AmbulanceDashboardScreen> {
  String? ambulanceId;
  bool _loaded = false;

  /// 🎧 AUDIO PLAYER (IMPORTANT FIX)
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? currentlyPlayingUrl;
  bool isPlaying = false;

  Future<void> loadAmbulanceId(AmbulanceDashboardViewModel vm) async {
    ambulanceId = await vm.getAmbulanceId(widget.ambulanceEmail);

    setState(() {
      _loaded = true;
    });
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    // still keeping maps external (fine)
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// 🎧 IN-APP AUDIO PLAYER (FIXED)
  Future<void> _playAudio(String url) async {
    try {
      /// If same audio is playing → stop it
      if (currentlyPlayingUrl == url && isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          isPlaying = false;
          currentlyPlayingUrl = null;
        });
        return;
      }

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      setState(() {
        currentlyPlayingUrl = url;
        isPlaying = true;
      });

      /// Auto reset when finished
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            isPlaying = false;
            currentlyPlayingUrl = null;
          });
        }
      });
    } catch (e) {
      debugPrint("Audio play error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceDashboardViewModel(),
      child: Consumer<AmbulanceDashboardViewModel>(
        builder: (context, vm, _) {
          if (!_loaded) {
            loadAmbulanceId(vm);
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (ambulanceId == null) {
            return const Scaffold(
              body: Center(child: Text("Ambulance not found ❌")),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text("Ambulance Dashboard 🚑"),
              backgroundColor: Colors.redAccent,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: vm.getSOSRequests(ambulanceId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No nearby SOS requests 🚫"),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final double lat =
                    (data['lat'] ?? 0).toDouble();
                    final double lng =
                    (data['lng'] ?? 0).toDouble();

                    final String? audioUrl = data['audioUrl'];

                    final bool isThisPlaying =
                        currentlyPlayingUrl == audioUrl && isPlaying;

                    return Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['patientName'] ?? "Unknown",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),

                            Text("📞 Phone: ${data['phone'] ?? 'N/A'}"),
                            const SizedBox(height: 5),

                            Text("📍 Lat: $lat, Lng: $lng"),

                            const SizedBox(height: 10),

                            /// 🎧 AUDIO BUTTON (IN-APP)
                            if (audioUrl != null)
                              ElevatedButton.icon(
                                onPressed: () => _playAudio(audioUrl),
                                icon: Icon(
                                  isThisPlaying
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  isThisPlaying
                                      ? "Stop Audio"
                                      : "Play SOS Audio",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                ),
                              ),

                            const Divider(),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _launchMaps(lat, lng),
                                    icon: const Icon(Icons.map),
                                    label: const Text("Open Map"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => vm.acceptRequest(
                                      doc.id,
                                      widget.ambulanceEmail,
                                    ),
                                    icon: const Icon(Icons.check),
                                    label: const Text("Accept"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}