import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/patient/search_doctor_by_symptom_viewmodel.dart';

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
                  /// 🔹 Ask user what they are feeling
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

                  /// 🔹 Text input for user symptoms
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

                  /// 🔍 Search Button
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

                  /// ⏳ Loader
                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator()),

                  /// 🧠 Predicted Department
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

                  /// 📝 Department messages if no doctors available
                  if (!vm.isLoading && vm.predictedDepartmentMessages.isNotEmpty)
                    Column(
                      children: vm.predictedDepartmentMessages.map((msg) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            msg,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  /// ❌ No doctors found
                  if (!vm.isLoading &&
                      vm.matchedDoctors.isEmpty &&
                      vm.predictedDepartmentMessages.isEmpty &&
                      vm.predictedSpecialty != null)
                    const Text(
                      "No doctors available for this department.",
                      style: TextStyle(color: Colors.grey),
                    ),

                  /// ✅ Doctor results
                  if (!vm.isLoading && vm.matchedDoctors.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.matchedDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = vm.matchedDoctors[index];
                          final name =
                              doctor['doctorName'] ?? 'Unknown Doctor';
                          final departments =
                          (doctor['departments'] as Set).join(', ');

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
                              title: Text(name),
                              subtitle: Text("Department: $departments"),
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
