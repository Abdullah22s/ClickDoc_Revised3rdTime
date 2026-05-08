import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/operator/operator_registration_viewmodel.dart';
import 'operator_dashboard_view.dart';

class OperatorRegistrationFormScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const OperatorRegistrationFormScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<OperatorRegistrationFormScreen> createState() => _OperatorRegistrationFormScreenState();
}

class _OperatorRegistrationFormScreenState extends State<OperatorRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(OperatorRegistrationViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await vm.registerOperator(
      name: _nameController.text,
      email: widget.userEmail,
    );

    if (success && mounted) {
      // ✅ FIX: Passed widget.userEmail and removed 'const'
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OperatorDashboardScreen(operatorEmail: widget.userEmail),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to register. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OperatorRegistrationViewModel(),
      child: Consumer<OperatorRegistrationViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Operator Registration"),
              backgroundColor: const Color(0xFFFB8C00), // Operator Theme Color
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Setup your Operator Profile",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "As an operator, you will be responsible for updating patient vitals and managing appointments.",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 40),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFB8C00), width: 2),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null,
                    ),
                    const SizedBox(height: 20),

                    // Email Field (Read Only)
                    TextFormField(
                      initialValue: widget.userEmail,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: vm.isSaving ? null : () => _handleRegister(vm),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB8C00),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: vm.isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Complete Registration",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                      ),
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