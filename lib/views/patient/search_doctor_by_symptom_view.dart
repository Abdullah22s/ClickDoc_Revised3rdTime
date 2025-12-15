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
                  // Dynamic dropdown list
                  ...List.generate(
                    vm.selectedSymptoms.length,
                        (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: vm.selectedSymptoms[index],
                              items: vm.symptoms
                                  .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) =>
                                  vm.updateSelectedSymptom(index, val),
                              decoration: InputDecoration(
                                labelText: "Select Symptom",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (vm.selectedSymptoms.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.redAccent),
                              onPressed: () => vm.removeSymptomField(index),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Add Symptom Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: vm.addSymptomField,
                      icon: const Icon(Icons.add, color: Colors.blueAccent),
                      label: const Text("Add Symptom"),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search Button
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

                  // Results Section
                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (vm.matchedDoctors.isEmpty)
                    const Text("No doctors found",
                        style: TextStyle(color: Colors.grey))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.matchedDoctors.length,
                        itemBuilder: (context, index) {
                          final doc = vm.matchedDoctors[index];
                          final name = doc['doctorName'] ??
                              doc['name'] ??
                              doc['doctor_name'] ??
                              'Unknown Doctor';

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin:
                            const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.blueAccent),
                              title: Text(name),
                              subtitle:
                              Text(doc['department'] ?? 'Unknown Department'),
                              trailing: Text(
                                doc['type'] ?? '',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
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
