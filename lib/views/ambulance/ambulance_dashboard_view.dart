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

  /// 📍 Load ambulance document ID
  Future<void> loadAmbulanceId(
      AmbulanceDashboardViewModel vm) async {
    ambulanceId =
    await vm.getAmbulanceId(widget.ambulanceEmail);
    setState(() {});
  }

  /// 🗺 Open Google Maps
  Future<void> _launchMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    if (await canLaunchUrl(url)) {
      await launchUrl(url,
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceDashboardViewModel(),
      child: Consumer<AmbulanceDashboardViewModel>(
        builder: (context, vm, _) {
          /// 🚀 Load ambulance ID once
          if (ambulanceId == null) {
            loadAmbulanceId(vm);
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text("Ambulance Dashboard 🚑"),
              backgroundColor: Colors.redAccent,
            ),
            body: StreamBuilder<QuerySnapshot>(
              /// ✅ PASS ambulanceId HERE
              stream: vm.getSOSRequests(ambulanceId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No nearby SOS requests 🚫"),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;

                    final double lat =
                    (data['lat'] as num).toDouble();
                    final double lng =
                    (data['lng'] as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['patientName'] ??
                                  "Unknown",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                                "📞 Phone: ${data['phone'] ?? 'N/A'}"),
                            const SizedBox(height: 5),

                            /// 📍 Optional: show coordinates
                            Text("📍 $lat, $lng"),

                            const Divider(),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _launchMaps(
                                            lat, lng),
                                    icon:
                                    const Icon(Icons.map),
                                    label: const Text(
                                        "Open Map"),
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child:
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        vm.acceptRequest(
                                          doc.id,
                                          widget.ambulanceEmail,
                                        ),
                                    icon: const Icon(
                                        Icons.check),
                                    label:
                                    const Text("Accept"),
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.green,
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