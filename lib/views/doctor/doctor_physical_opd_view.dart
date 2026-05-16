import 'package:clickdoc1/viewmodels/doctor/doctor_physical_opd_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DoctorPhysicalOpdView extends StatelessWidget {
  const DoctorPhysicalOpdView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorPhysicalOpdViewmodel(),
      child: Consumer<DoctorPhysicalOpdViewmodel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text(
                "Physical OPD Setup",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
            ),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDoctorCard(vm),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Location & Schedule"),
                  const SizedBox(height: 12),
                  _buildInputCard(context, vm),
                  const SizedBox(height: 24),
                  if (vm.previewSlots.isNotEmpty) ...[
                    _buildSectionTitle("Preview Slots"),
                    const SizedBox(height: 12),
                    _buildSlotsPreview(vm),
                  ],
                  const SizedBox(height: 32),
                  _buildSaveButton(context, vm),
                  const SizedBox(height: 40),
                  if (vm.createdClinics.isNotEmpty) ...[
                    _buildSectionTitle("Existing Schedules"),
                    const SizedBox(height: 12),
                    ClinicSlotsDropdown(vm: vm),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDoctorCard(DoctorPhysicalOpdViewmodel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. ${vm.doctorName}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Color(0xFF1E3A8A)
                  ),
                ),
                Text(
                  vm.doctorQualification.isNotEmpty ? vm.doctorQualification : "Healthcare Professional",
                  style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, DoctorPhysicalOpdViewmodel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // City and Hospital Fields
          TextField(
            controller: vm.cityController,
            decoration: _inputDecoration("City", Icons.location_city_rounded),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: vm.hospitalController,
            decoration: _inputDecoration("Hospital / Clinic Name", Icons.apartment_rounded),
          ),
          const SizedBox(height: 20),

          _buildActionRow(
            icon: Icons.calendar_today_rounded,
            label: vm.selectedDate == null
                ? "Select Session Date"
                : "Date: ${vm.selectedDate!.toLocal().toString().split(' ')[0]}",
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 180)),
              );
              if (picked != null) vm.setSelectedDate(picked);
            },
          ),
          const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
          DropdownButtonFormField<String>(
            value: vm.selectedDepartment.isEmpty ? null : vm.selectedDepartment,
            decoration: _inputDecoration("Department", Icons.local_hospital_outlined),
            items: vm.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) => val != null ? vm.setDepartment(val) : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionRow(
                  icon: Icons.access_time_rounded,
                  label: vm.startTime == null ? "Start" : vm.formatTime(vm.startTime!),
                  onTap: () async {
                    final p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (p != null) vm.setStartTime(p);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionRow(
                  icon: Icons.timer_off_outlined,
                  label: vm.endTime == null ? "End" : vm.formatTime(vm.endTime!),
                  onTap: () async {
                    final p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (p != null) vm.setEndTime(p);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: vm.feesController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: _inputDecoration("OPD Fee (PKR)", Icons.payments_outlined),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: vm.appointmentDuration,
                  decoration: _inputDecoration("Duration", Icons.hourglass_top_rounded),
                  items: vm.appointmentOptions.map((v) => DropdownMenuItem(value: v, child: Text("$v min"))).toList(),
                  onChanged: (v) => v != null ? vm.setAppointmentDuration(v) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: vm.bufferDuration,
                  decoration: _inputDecoration("Buffer", Icons.coffee_outlined),
                  items: vm.bufferOptions.map((v) => DropdownMenuItem(value: v, child: Text("$v min"))).toList(),
                  onChanged: (v) => v != null ? vm.setBufferDuration(v) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _buildSlotsPreview(DoctorPhysicalOpdViewmodel vm) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vm.previewSlots.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
              ]
          ),
          child: Text(
            "${s['start']} - ${s['end']}",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(BuildContext context, DoctorPhysicalOpdViewmodel vm) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: vm.isSaving
            ? null
            : () async {
          final String? error = await vm.saveClinic();
          if (context.mounted) {
            if (error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error, style: const TextStyle(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Physical OPD Schedule Created!"),
                  backgroundColor: const Color(0xFF3B82F6),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
        child: vm.isSaving
            ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
        )
            : const Text(
            "Create Physical OPD",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)
        ),
      ),
    );
  }
}

class ClinicSlotsDropdown extends StatefulWidget {
  final DoctorPhysicalOpdViewmodel vm;
  const ClinicSlotsDropdown({required this.vm, super.key});

  @override
  State<ClinicSlotsDropdown> createState() => _ClinicSlotsDropdownState();
}

class _ClinicSlotsDropdownState extends State<ClinicSlotsDropdown> {
  Map<String, dynamic>? selectedClinic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
          ]
      ),
      child: Column(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              hint: const Text("Select a schedule to view slots", style: TextStyle(color: Color(0xFF64748B))),
              value: selectedClinic,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3B82F6)),
              items: widget.vm.createdClinics.map((clinic) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: clinic,
                  child: Text(
                      "${clinic['hospitalName']} | ${clinic['department']}",
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedClinic = val),
            ),
          ),
          if (selectedClinic != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(thickness: 1, color: Color(0xFFF1F5F9)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.vm.getClinicSlots(selectedClinic!).map((slot) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${slot['start']} - ${slot['end']}",
                    style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                );
              }).toList(),
            )
          ]
        ],
      ),
    );
  }
}