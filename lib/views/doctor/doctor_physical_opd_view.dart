import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/doctor/doctor_physical_opd_viewmodel.dart';

class DoctorPhysicalOpdScreen extends StatelessWidget {
  const DoctorPhysicalOpdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorPhysicalOpdViewModel(),
      child: Consumer<DoctorPhysicalOpdViewModel>(
        builder: (context, vm, _) {
          /// Widget to select time for each day
          Widget buildDayTimeSelector(String day) {
            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (picked != null) vm.setFromTime(day, picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: "$day From"),
                      child: Text(vm.fromTimes[day] != null
                          ? vm.formatTime(vm.fromTimes[day]!)
                          : "--:--"),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (picked != null) vm.setToTime(day, picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: "$day To"),
                      child: Text(vm.toTimes[day] != null
                          ? vm.formatTime(vm.toTimes[day]!)
                          : "--:--"),
                    ),
                  ),
                ),
              ],
            );
          }

          /// Form to add a new OPD
          Widget buildAddOpdForm() {
            if (vm.loading) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Card(
              elevation: 3,
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dr. ${vm.doctorName} (${vm.doctorQualification})",
                      style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: vm.hospitalController,
                      decoration: const InputDecoration(labelText: "Hospital/Clinic"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: vm.selectedDepartment,
                      decoration: const InputDecoration(
                          labelText: "Department / Specialization"),
                      items: vm.departments
                          .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                          .toList(),
                      onChanged: (val) => vm.selectedDepartment = val,
                    ),
                    const SizedBox(height: 12),
                    const Text("Select Days & Time",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 6,
                      children: vm.daysSelected.keys
                          .map((day) => FilterChip(
                        label: Text(day),
                        selected: vm.daysSelected[day]!,
                        onSelected: (val) => vm.toggleDay(day, val),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: vm.daysSelected.entries
                          .where((e) => e.value)
                          .map((e) => buildDayTimeSelector(e.key))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton(
                          onPressed: vm.addOpd, child: const Text("Add OPD")),
                    ),
                  ],
                ),
              ),
            );
          }

          /// List of OPDs
          Widget buildOpdList() {
            return StreamBuilder(
              stream: vm.getOpdStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    (snapshot.data as dynamic).docs.isEmpty) {
                  return const Center(child: Text("No OPDs added yet."));
                }

                final opdDocs = (snapshot.data as dynamic).docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: opdDocs.length,
                  itemBuilder: (context, index) {
                    final opd = opdDocs[index].data();
                    return Card(
                      margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital,
                            color: Colors.blueAccent),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dr. ${vm.doctorName} (${vm.doctorQualification})",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text("${opd['day']}: ${opd['hospitalName']}"),
                            if (opd['department'] != null)
                              Text("Department: ${opd['department']}"),
                          ],
                        ),
                        subtitle: Text("${opd['fromTime']} - ${opd['toTime']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => vm.deleteOpd(opdDocs[index].id),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text("Physical OPDs"),
              backgroundColor: Colors.blueAccent,
            ),
            body: Column(
              children: [
                buildAddOpdForm(),
                const SizedBox(height: 20),
                Expanded(child: buildOpdList())
              ],
            ),
          );
        },
      ),
    );
  }
}
