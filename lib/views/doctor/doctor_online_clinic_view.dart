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
          // Non-nullable reference
          final viewModel = vm;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Online Clinic Setup"),
              backgroundColor: Colors.blueAccent,
            ),
            body: viewModel.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Info
                  Text(
                    "Dr. ${viewModel.doctorName} ${viewModel.doctorQualification.isNotEmpty ? "(${viewModel.doctorQualification})" : ""}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        viewModel.setSelectedDate(picked);
                      }
                    },
                    child: Text(
                      viewModel.selectedDate == null
                          ? "Select Date"
                          : "Date: ${viewModel.selectedDate!.toLocal().toString().split(' ')[0]}",
                    ),
                  ),

                  if (viewModel.selectedDays.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Selected Day: ${viewModel.selectedDays.first}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Department
                  DropdownButtonFormField<String>(
                    value: viewModel.selectedDepartment.isEmpty ? null : viewModel.selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: "Department / Specialization",
                      border: OutlineInputBorder(),
                    ),
                    items: viewModel.departments
                        .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setDepartment(val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) viewModel.setStartTime(picked);
                          },
                          child: Text(
                            viewModel.startTime == null
                                ? "Start Time"
                                : "Start: ${viewModel.formatTime(viewModel.startTime!)}",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) viewModel.setEndTime(picked);
                          },
                          child: Text(
                            viewModel.endTime == null
                                ? "End Time"
                                : "End: ${viewModel.formatTime(viewModel.endTime!)}",
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Fees
                  TextField(
                    controller: viewModel.feesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Fees (PKR)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Appointment & Buffer Duration
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: viewModel.appointmentDuration,
                          decoration: const InputDecoration(
                            labelText: "Appointment Duration (minutes)",
                            border: OutlineInputBorder(),
                          ),
                          items: viewModel.appointmentOptions
                              .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text("$v min"),
                          ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) viewModel.setAppointmentDuration(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: viewModel.bufferDuration,
                          decoration: const InputDecoration(
                            labelText: "Buffer Duration (minutes)",
                            border: OutlineInputBorder(),
                          ),
                          items: viewModel.bufferOptions
                              .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text("$v min"),
                          ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) viewModel.setBufferDuration(val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preview Slots
                  if (viewModel.previewSlots.isNotEmpty) ...[
                    const Text(
                      "Preview Slots",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...viewModel.previewSlots.map((s) => Text("${s['start']} - ${s['end']}")),
                  ],

                  const SizedBox(height: 24),

                  // Save Button
                  Center(
                    child: ElevatedButton(
                      onPressed: viewModel.isSaving ? null : viewModel.saveClinic,
                      child: Text(viewModel.isSaving ? "Saving..." : "Save Online Clinic"),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Created Clinics Dropdown
                  if (viewModel.createdClinics.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      "Created Online Clinics",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClinicSlotsDropdown(vm: viewModel),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ClinicSlotsDropdown extends StatefulWidget {
  final DoctorOnlineClinicViewModel vm;
  const ClinicSlotsDropdown({required this.vm, super.key});

  @override
  State<ClinicSlotsDropdown> createState() => _ClinicSlotsDropdownState();
}

class _ClinicSlotsDropdownState extends State<ClinicSlotsDropdown> {
  Map<String, dynamic>? selectedClinic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<Map<String, dynamic>>(
          hint: const Text("Select Clinic to view slots"),
          value: selectedClinic,
          isExpanded: true,
          items: widget.vm.createdClinics.map((clinic) {
            final title = "${clinic['department']} (${clinic['startTime']} - ${clinic['endTime']})";
            return DropdownMenuItem<Map<String, dynamic>>(
              value: clinic,
              child: Text(title),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedClinic = val;
            });
          },
        ),
        const SizedBox(height: 8),
        if (selectedClinic != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Slots for selected clinic:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...widget.vm.getClinicSlots(selectedClinic!).map(
                    (slot) => Text("${slot['start']} - ${slot['end']}"),
              ),
            ],
          ),
      ],
    );
  }
}
