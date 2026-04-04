import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ambulance/ambulance_registration_viewmodel.dart';

class AmbulanceRegistrationFormScreen extends StatelessWidget {
  final String userName;
  final String userEmail;

  const AmbulanceRegistrationFormScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceRegistrationViewModel(),
      child: Consumer<AmbulanceRegistrationViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Ambulance Registration'),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// 👤 Welcome
                  Text(
                    "Welcome, $userName 🚑",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// 🚑 Service Name
                  TextField(
                    controller: vm.serviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Service Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 📞 Phone Number
                  TextField(
                    controller: vm.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🚨 Register Button
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => vm.registerAmbulance(
                        context,
                        userEmail,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Register Ambulance",
                        style: TextStyle(fontSize: 18),
                      ),
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