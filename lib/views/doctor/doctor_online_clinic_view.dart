import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/doctor/doctor_online_clinic_viewmodel.dart';

class DoctorOnlineClinicScreen extends StatelessWidget {
  const DoctorOnlineClinicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorOnlineClinicViewModel(),
      child: Consumer<DoctorOnlineClinicViewModel>(
        builder: (context, vm, _) {
          final days = [
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday'
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text("Online Clinic Setup"),
              backgroundColor: Colors.blueAccent,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr. ${vm.doctorName} (${vm.doctorQualification})",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text("Department / Specialization",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: vm.selectedDepartment.isNotEmpty ? vm.selectedDepartment : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Department",
                    ),
                    items: vm.departments.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) vm.selectedDepartment = val;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Select Days", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: days.map((day) {
                      final isSelected = vm.selectedDays.contains(day);
                      return ChoiceChip(
                        label: Text(day),
                        selected: isSelected,
                        onSelected: (_) => vm.toggleDay(day),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now());
                            if (picked != null) vm.startTime = picked;
                          },
                          child: Text(vm.startTime == null
                              ? "Select Start Time"
                              : "Start: ${vm.startTime!.format(context)}"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now());
                            if (picked != null) vm.endTime = picked;
                          },
                          child: Text(vm.endTime == null
                              ? "Select End Time"
                              : "End: ${vm.endTime!.format(context)}"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: vm.feesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Fees (PKR)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: vm.appointmentDuration,
                          decoration: const InputDecoration(
                            labelText: "Appointment Duration (min)",
                            border: OutlineInputBorder(),
                          ),
                          items: vm.appointmentOptions.map((val) {
                            return DropdownMenuItem(value: val, child: Text("$val min"));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) vm.appointmentDuration = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: vm.bufferDuration,
                          decoration: const InputDecoration(
                            labelText: "Buffer Duration (min)",
                            border: OutlineInputBorder(),
                          ),
                          items: vm.bufferOptions.map((val) {
                            return DropdownMenuItem(value: val, child: Text("$val min"));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) vm.bufferDuration = val;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: vm.isSaving ? null : vm.saveClinic,
                      child: Text(vm.isSaving ? "Saving..." : "Save Online Clinic"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (vm.startTime != null && vm.endTime != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Preview Slots:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...vm.generateSlots().map((slot) => Text("${slot.start} - ${slot.end}")).toList(),
                      ],
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
