import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/patient/search_doctor_by_symptom_viewmodel.dart';

class SearchDoctorBySymptomView extends StatelessWidget {
  const SearchDoctorBySymptomView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = SearchDoctorBySymptomViewModel();
        vm.loadSymptomData();
        return vm;
      },
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
                  /// 🔹 Symptom Text Fields
                  ...List.generate(
                    vm.symptomControllers.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: vm.symptomControllers[index],
                              decoration: InputDecoration(
                                labelText: index == 0
                                    ? "Enter your main symptom"
                                    : "Enter another symptom",
                                hintText: "e.g. fever, cough, headache",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (vm.symptomControllers.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  vm.removeSymptomField(index),
                            ),
                        ],
                      ),
                    ),
                  ),

                  /// ➕ Add Symptom
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: vm.addSymptomField,
                      icon: const Icon(Icons.add, color: Colors.blueAccent),
                      label: const Text("Add Symptom"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔍 Search Button
                  ElevatedButton.icon(
                    onPressed: vm.searchDoctors,
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

                  /// 🧠 Predicted Department Messages
                  if (!vm.isLoading &&
                      vm.predictedDepartmentMessages.isNotEmpty)
                    Column(
                      children: vm.predictedDepartmentMessages.map((msg) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueAccent),
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

                  /// ❌ No Doctors Found
                  if (!vm.isLoading &&
                      vm.matchedDoctors.isEmpty &&
                      vm.predictedDepartmentMessages.isEmpty)
                    const Text(
                      "No doctors available for the entered symptoms.",
                      style: TextStyle(color: Colors.grey),
                    ),

                  /// ✅ Doctor Results
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
                            margin:
                            const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blueAccent,
                              ),
                              title: Text(name),
                              subtitle:
                              Text("Department: $departments"),
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
