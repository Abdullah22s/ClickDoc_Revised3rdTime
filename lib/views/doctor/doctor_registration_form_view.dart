import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor/doctor_registration_model.dart';
import '../../viewmodels/doctor/doctor_registration_viewmodel.dart';
import '../../viewmodels/doctor/doctor_dashboard_viewmodel.dart';
import 'doctor_dashboard_view.dart';

class DoctorRegistrationFormScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const DoctorRegistrationFormScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<DoctorRegistrationFormScreen> createState() =>
      _DoctorRegistrationFormScreenState();
}

class _DoctorRegistrationFormScreenState
    extends State<DoctorRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();

  List<String?> qualifications = [null];
  final List<String> availableQualifications = [
    'MBBS',
    'FCPS',
    'MS',
    'MD',
    'MRCP',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorRegistrationViewModel(),
      child: Consumer<DoctorRegistrationViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text("Doctor Registration")),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "Welcome Dr. ${widget.userName}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Enter your phone number" : null,
                    ),
                    const SizedBox(height: 20),

                    // License Number
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(
                        labelText: "License Number",
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Enter license number" : null,
                    ),
                    const SizedBox(height: 20),

                    // Experience
                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Years of Experience",
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Enter experience" : null,
                    ),
                    const SizedBox(height: 20),

                    // Multiple Qualifications
                    Column(
                      children: List.generate(qualifications.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: qualifications[index],
                                  decoration: InputDecoration(
                                    labelText: "Qualification ${index + 1}",
                                    prefixIcon: const Icon(Icons.school),
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: availableQualifications
                                      .map((q) =>
                                      DropdownMenuItem(value: q, child: Text(q)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      qualifications[index] = value;
                                      if (value != null &&
                                          index == qualifications.length - 1) {
                                        qualifications.add(null);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (qualifications.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      qualifications.removeAt(index);
                                      if (qualifications.isEmpty)
                                        qualifications = [null];
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),

                    vm.isSaving
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save & Continue"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        final doctorModel = DoctorRegistrationModel(
                          name: widget.userName,
                          email: widget.userEmail,
                          phone: _phoneController.text.trim(),
                          licenseNumber: _licenseController.text.trim(),
                          experience: _experienceController.text.trim(),
                          qualifications: qualifications
                              .where((q) => q != null)
                              .map((q) => q!)
                              .toList(),
                        );

                        final errorMessage =
                        await vm.saveDoctorData(doctor: doctorModel);

                        if (errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMessage)),
                          );
                        } else {
                          // Create ViewModel for Dashboard
                          final dashboardViewModel =
                          DoctorDashboardViewModel(
                            userName: widget.userName,
                            userEmail: widget.userEmail,
                            userPhotoUrl: widget.userPhotoUrl,
                          );

                          // Navigate to Dashboard
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorDashboardScreen(
                                viewModel: dashboardViewModel,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
