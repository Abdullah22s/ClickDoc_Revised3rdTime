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
              backgroundColor: const Color(0xFF2563EB),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4FC3F7), Color(0xFF50C9C3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      child: Column(
                        children: [
                          Text(
                            "Welcome, $userName",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: vm.ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Age",
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: vm.weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Weight (kg)",
                              prefixIcon: Icon(Icons.monitor_weight),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          DropdownButtonFormField<String>(
                            value: vm.selectedGender,
                            decoration: const InputDecoration(
                              labelText: "Gender",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (value) {
                              vm.selectedGender = value;
                              vm.notifyListeners();
                            },
                          ),
                          const SizedBox(height: 20),

                          Column(
                            children: List.generate(vm.selectedDiseases.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: vm.selectedDiseases[index],
                                        decoration: InputDecoration(
                                          labelText: "Medical History (Disease ${index + 1})",
                                          prefixIcon: const Icon(Icons.medical_information),
                                          border: const OutlineInputBorder(),
                                        ),
                                        items: vm.diseases
                                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                            .toList(),
                                        onChanged: (value) => vm.addDiseaseRow(index, value),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (vm.selectedDiseases.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => vm.removeDiseaseRow(index),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 40),

                          vm.isSaving
                              ? const CircularProgressIndicator()
                              : ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text(
                              "Save and Continue",
                              style: TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              await vm.savePatientData(userName: userName, context: context);

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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
