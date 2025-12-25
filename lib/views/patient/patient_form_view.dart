import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodels/patient/patient_form_viewmodel.dart';
import 'patient_dashboard_view.dart';

class PatientFormScreen extends StatelessWidget {
  final String userName;

  const PatientFormScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientFormViewModel(),
      child: Consumer<PatientFormViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Patient Information"),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Age
                  TextFormField(
                    controller: vm.ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Age",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Weight
                  TextFormField(
                    controller: vm.weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Weight (kg)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Gender
                  DropdownButtonFormField<String>(
                    value: vm.selectedGender,
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(),
                    ),
                    items: ['Male','Female','Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => vm.selectedGender = v,
                  ),
                  const SizedBox(height: 16),

                  /// Blood Group
                  DropdownButtonFormField<String>(
                    value: vm.selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: "Blood Group",
                      border: OutlineInputBorder(),
                    ),
                    items: vm.bloodGroups
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => vm.selectedBloodGroup = v,
                  ),

                  const SizedBox(height: 30),

                  /// Major illness
                  const Text(
                    "Do you have any major illness?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Selected illnesses
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: vm.selectedDiseases.map((disease) {
                      return Chip(
                        label: Text(disease),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => vm.removeDisease(disease),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  /// Add button
                  if (vm.selectedDiseases.length < 3)
                    OutlinedButton.icon(
                      onPressed: vm.toggleDiseaseOptions,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Major Illness"),
                    ),

                  /// Disease options
                  if (vm.showDiseaseOptions)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: vm.availableDiseases.map((disease) {
                          return InkWell(
                            onTap: () => vm.selectDisease(disease),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Text(
                                disease,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 30),

                  /// Save
                  vm.isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: () async {
                      await vm.savePatientData(
                        userName: userName,
                        context: context,
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientDashboardScreen(
                            userName: userName,
                            userEmail: FirebaseAuth.instance.currentUser?.email ?? "",
                            userPhotoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                          ),
                        ),
                      );
                    },
                    child: const Text("Save & Continue"),
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
