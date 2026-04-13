import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// 🎧 PLAY SOS AUDIO
  Future<void> _playAudio(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Cannot open audio URL");
    }
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

                            /// 🎧 AUDIO BUTTON (NEW)
                            if (audioUrl != null)
                              ElevatedButton.icon(
                                onPressed: () => _playAudio(audioUrl),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text("Play SOS Audio"),
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