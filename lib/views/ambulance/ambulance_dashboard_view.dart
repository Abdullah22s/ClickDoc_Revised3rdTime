import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/ambulance/ambulance_dashboard_viewmodel.dart';

class AmbulanceDashboardScreen extends StatelessWidget {
  final String ambulanceEmail;

  const AmbulanceDashboardScreen({
    super.key,
    required this.ambulanceEmail,
  });

  // Opens Google Maps using the lat/lng from the SOS request
  Future<void> _launchMaps(double lat, double lng) async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Map Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceDashboardViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ambulance Dashboard 🚑"),
          backgroundColor: Colors.redAccent,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => (context as Element).markNeedsBuild(),
            ),
          ],
        ),
        body: Consumer<AmbulanceDashboardViewModel>(
          builder: (context, vm, _) {
            return StreamBuilder<QuerySnapshot>(
              stream: vm.getSOSRequests(),
              builder: (context, snapshot) {
                // Displays the specific building-index error if it's still processing
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(child: Text("Status: ${snapshot.error}")),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Waiting for active index or new requests..."),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Safe parsing for numeric values
                    final double lat = (data['lat'] as num).toDouble();
                    final double lng = (data['lng'] as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['patientName'] ?? "Unknown",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text("📞 Phone: ${data['phone'] ?? 'N/A'}"),
                            const Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchMaps(lat, lng),
                                    icon: const Icon(Icons.map),
                                    label: const Text("Open Map"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => vm.acceptRequest(doc.id, ambulanceEmail),
                                    icon: const Icon(Icons.check),
                                    label: const Text("Accept"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
            );
          },
        ),
      ),
    );
  }
}