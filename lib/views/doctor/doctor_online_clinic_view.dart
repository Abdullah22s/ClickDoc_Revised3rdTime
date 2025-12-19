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

                  /// -------- DOCTOR INFO --------
                  Text(
                    "Dr. ${vm.doctorName} (${vm.doctorQualification})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// -------- DATE PICKER --------
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        vm.setSelectedDate(picked);
                      }
                    },
                    child: Text(
                      vm.selectedDate == null
                          ? "Select Date"
                          : "Date: ${vm.selectedDate!.toLocal().toString().split(' ')[0]}",
                    ),
                  ),

                  if (vm.selectedDays.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Selected Day: ${vm.selectedDays.first}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],

                  const SizedBox(height: 12),

                  /// -------- REPEAT WEEKS --------
                  DropdownButtonFormField<int>(
                    value: vm.repeatWeeks,
                    decoration: const InputDecoration(
                      labelText: "Apply Schedule For",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Only this date")),
                      DropdownMenuItem(value: 2, child: Text("Next 2 weeks")),
                      DropdownMenuItem(value: 4, child: Text("Next 4 weeks")),
                    ],
                    onChanged: (val) {
                      if (val != null) vm.setRepeatWeeks(val);
                    },
                  ),

                  const SizedBox(height: 8),

                  /// -------- GENERATED DATES --------
                  if (vm.getGeneratedDates().isNotEmpty) ...[
                    const Text(
                      "Applies On:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...vm.getGeneratedDates().map(
                          (d) => Text(
                        "• ${d.toLocal().toString().split(' ')[0]}",
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  /// -------- DEPARTMENT --------
                  DropdownButtonFormField<String>(
                    value: vm.selectedDepartment.isEmpty
                        ? null
                        : vm.selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: "Department / Specialization",
                      border: OutlineInputBorder(),
                    ),
                    items: vm.departments
                        .map(
                          (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) vm.setDepartment(val);
                    },
                  ),

                  const SizedBox(height: 16),

                  /// -------- TIME PICKERS --------
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) vm.setStartTime(picked);
                          },
                          child: Text(
                            vm.startTime == null
                                ? "Start Time"
                                : "Start: ${vm.formatTime(vm.startTime!)}",
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
                            if (picked != null) vm.setEndTime(picked);
                          },
                          child: Text(
                            vm.endTime == null
                                ? "End Time"
                                : "End: ${vm.formatTime(vm.endTime!)}",
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// -------- FEES --------
                  TextField(
                    controller: vm.feesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Fees (PKR)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// -------- DURATIONS --------
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: vm.appointmentDuration,
                          decoration: const InputDecoration(
                            labelText: "Appointment Duration (min)",
                            border: OutlineInputBorder(),
                          ),
                          items: vm.appointmentOptions
                              .map(
                                (v) => DropdownMenuItem(
                              value: v,
                              child: Text("$v min"),
                            ),
                          )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) vm.setAppointmentDuration(val);
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
                          items: vm.bufferOptions
                              .map(
                                (v) => DropdownMenuItem(
                              value: v,
                              child: Text("$v min"),
                            ),
                          )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) vm.setBufferDuration(val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// -------- SLOT PREVIEW --------
                  if (vm.previewSlots.isNotEmpty) ...[
                    const Text(
                      "Preview Slots",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...vm.previewSlots.map(
                          (s) => Text("${s.start} - ${s.end}"),
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// -------- SAVE BUTTON --------
                  Center(
                    child: ElevatedButton(
                      onPressed: vm.isSaving ? null : vm.saveClinic,
                      child: Text(
                        vm.isSaving ? "Saving..." : "Save Online Clinic",
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// -------- CREATED CLINICS (SAME TAB) --------
                  if (vm.createdClinics.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      "Created Online Clinics",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...vm.createdClinics.map(
                          (c) => Card(
                        child: ListTile(
                          title: Text(
                            "${c['department']} (${c['startTime']} - ${c['endTime']})",
                          ),
                          subtitle: Text(
                            "Days: ${(c['days'] as List).join(', ')} | Fees: PKR ${c['fees']}",
                          ),
                        ),
                      ),
                    ),
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
