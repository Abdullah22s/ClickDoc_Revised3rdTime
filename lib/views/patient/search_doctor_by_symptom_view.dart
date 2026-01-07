import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/patient/search_doctor_by_symptom_viewmodel.dart';
import 'patient_online_doctors_view.dart';
import 'patient_physical_opd_view.dart';

class SearchDoctorBySymptomView extends StatelessWidget {
  const SearchDoctorBySymptomView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchDoctorBySymptomViewModel(),
      child: Consumer<SearchDoctorBySymptomViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Search Doctor by Symptom"),
              backgroundColor: Colors.blueAccent,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "What are you feeling?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: vm.messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Describe your symptoms...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: vm.predictAndFetchDoctors,
                    icon: const Icon(Icons.search),
                    label: const Text("Find Doctors"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator()),

                  if (!vm.isLoading && vm.predictedSpecialty != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Text(
                        "Predicted Department: ${vm.predictedSpecialty}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (!vm.isLoading && vm.matchedDoctors.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.matchedDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = vm.matchedDoctors[index];
                          final name = doctor['doctorName'];
                          final hasOnline = doctor['hasOnline'] == true;
                          final hasPhysical = doctor['hasPhysical'] == true;

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blueAccent,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Department: ${vm.predictedSpecialty}",
                              ),
                              trailing: ElevatedButton(
                                child: const Text("See Doctor"),
                                onPressed: () {
                                  /// ONLY ONLINE
                                  if (hasOnline && !hasPhysical) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const PatientOnlineDoctorsView(),
                                      ),
                                    );
                                  }
                                  /// ONLY PHYSICAL
                                  else if (!hasOnline && hasPhysical) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const PatientPhysicalOpdView(),
                                      ),
                                    );
                                  }
                                  /// BOTH → ASK USER
                                  else {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.video_call),
                                            title:
                                            const Text("Online Consultation"),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                  const PatientOnlineDoctorsView(),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading:
                                            const Icon(Icons.local_hospital),
                                            title:
                                            const Text("Physical OPD Visit"),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                  const PatientPhysicalOpdView(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
