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

          String doctorTitle() {
            return vm.doctorQualification.isNotEmpty
                ? "Dr. ${vm.doctorName} (${vm.doctorQualification})"
                : "Dr. ${vm.doctorName}";
          }

          Widget buildDayTimeSelector(String day) {
            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
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
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
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

          Widget buildAddOpdForm() {
            if (vm.loading) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorTitle(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    /// Hospital
                    TextField(
                      controller: vm.hospitalController,
                      decoration:
                      const InputDecoration(labelText: "Hospital / Clinic"),
                    ),

                    const SizedBox(height: 12),

                    /// City (First letter forced uppercase)
                    TextField(
                      controller: vm.cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "City",
                        hintText: "e.g. Lahore",
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final formatted =
                              value[0].toUpperCase() + value.substring(1);
                          if (formatted != value) {
                            vm.cityController.value =
                                vm.cityController.value.copyWith(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: vm.selectedDepartment,
                      decoration:
                      const InputDecoration(labelText: "Department"),
                      items: vm.departments
                          .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => vm.selectedDepartment = v,
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 6,
                      children: vm.daysSelected.keys
                          .map((day) => FilterChip(
                        label: Text(day),
                        selected: vm.daysSelected[day]!,
                        onSelected: (v) => vm.toggleDay(day, v),
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
                        onPressed: vm.addOpd,
                        child: const Text("Add OPD"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildOpdList() {
            return StreamBuilder(
              stream: vm.getOpdStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    (snapshot.data as dynamic).docs.isEmpty) {
                  return const Center(child: Text("No OPDs added yet"));
                }

                final docs = (snapshot.data as dynamic).docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final opd = docs[i].data();
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital,
                            color: Colors.blueAccent),
                        title: Text(doctorTitle(),
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${opd['day']} - ${opd['hospitalName']}"),
                            Text("City: ${opd['city']}"),
                            Text("${opd['fromTime']} - ${opd['toTime']}"),
                            if (opd['department'] != null)
                              Text("Dept: ${opd['department']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => vm.deleteOpd(docs[i].id),
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
                Expanded(child: buildOpdList()),
              ],
            ),
          );
        },
      ),
    );
  }
}
