import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clickdoc1/viewmodels/patient/patient_physical_opd_viewmodel.dart';
import 'package:clickdoc1/models/patient/patient_physical_opd_model.dart';
import 'package:clickdoc1/services/doctor_search_service.dart';

class PatientPhysicalOpdView extends StatefulWidget {
  const PatientPhysicalOpdView({super.key});

  @override
  State<PatientPhysicalOpdView> createState() => _PatientPhysicalOpdViewState();
}

class _PatientPhysicalOpdViewState extends State<PatientPhysicalOpdView> {
  final DoctorSearchService _searchService = DoctorSearchService();

  String? _name;
  String? _city;
  String? _department;

  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientPhysicalOpdViewModel(),
      child: Consumer<PatientPhysicalOpdViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Doctors & OPDs"),
              backgroundColor: Colors.blueAccent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _openFilterSheet(context),
                ),
              ],
            ),
            body: _isSearching
                ? _buildSearchResult(vm)
                : _buildStreamResult(vm),
          );
        },
      ),
    );
  }

  /// 🔎 STREAM MODE
  Widget _buildStreamResult(PatientPhysicalOpdViewModel vm) {
    return StreamBuilder<List<DoctorPhysicalOpdModel>>(
      stream: vm.doctorOpdStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No OPDs available."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _doctorCard(vm, snapshot.data![index]);
          },
        );
      },
    );
  }

  /// 🔍 SEARCH MODE
  Widget _buildSearchResult(PatientPhysicalOpdViewModel vm) {
    return FutureBuilder(
      future: _searchService.searchDoctors(
        name: _name,
        city: _city,
        department: _department,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No OPDs found."));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.map((doc) {
            return FutureBuilder<DoctorPhysicalOpdModel?>(
              future: vm.getDoctorInfo(doc.id),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                return _doctorCard(vm, snap.data!);
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// 🧩 DOCTOR CARD (UNCHANGED)
  Widget _doctorCard(
      PatientPhysicalOpdViewModel vm, DoctorPhysicalOpdModel doctor) {
    final isExpanded = vm.expandedDoctor[doctor.id] ?? false;
    final firstOpd = doctor.opds.first;

    final qualificationsText = doctor.qualifications.isNotEmpty
        ? " (${doctor.qualifications.join(', ')})"
        : "";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: Text(
              "Dr. ${doctor.name}$qualificationsText",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Department: ${firstOpd.department}"),
                Text("City: ${firstOpd.city}"),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () =>
                  vm.toggleDoctorExpansion(doctor.id),
            ),
          ),
          if (isExpanded)
            ...doctor.opds.map((opd) => ListTile(
              title: Text("${opd.day}: ${opd.hospitalName}"),
              subtitle:
              Text("${opd.fromTime} - ${opd.toTime}"),
            )),
        ],
      ),
    );
  }

  /// 🎛 FILTER BOTTOM SHEET
  void _openFilterSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _name);
    final cityCtrl = TextEditingController(text: _city);
    final deptCtrl = TextEditingController(text: _department);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                const InputDecoration(labelText: "Doctor Name"),
              ),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: "City"),
              ),
              TextField(
                controller: deptCtrl,
                decoration:
                const InputDecoration(labelText: "Department"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _name = nameCtrl.text;
                    _city = cityCtrl.text;
                    _department = deptCtrl.text;
                    _isSearching = true;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Apply Filters"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _name = null;
                    _city = null;
                    _department = null;
                    _isSearching = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Clear Filters"),
              ),
            ],
          ),
        );
      },
    );
  }
}
