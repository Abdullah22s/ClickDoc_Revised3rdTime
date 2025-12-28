import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Case-insensitive search without changing Firestore structure
  /// Supports:
  /// - name
  /// - city
  /// - department
  /// - any combination (1, 2, or 3 fields)
  Future<List<QueryDocumentSnapshot>> searchDoctors({
    String? name,
    String? city,
    String? department,
  }) async {
    final nameQuery = name?.trim().toLowerCase() ?? '';
    final cityQuery = city?.trim().toLowerCase() ?? '';
    final deptQuery = department?.trim().toLowerCase() ?? '';

    /// 1️⃣ Fetch ALL doctors (no where clause → no limitation)
    final doctorsSnapshot = await _firestore.collection('doctors').get();

    final List<QueryDocumentSnapshot> resultDoctors = [];

    for (final doctorDoc in doctorsSnapshot.docs) {
      final doctorData = doctorDoc.data() as Map<String, dynamic>;

      final doctorName =
      (doctorData['name'] ?? '').toString().toLowerCase();

      /// 🔹 NAME FILTER (local, case-insensitive)
      if (nameQuery.isNotEmpty &&
          !doctorName.contains(nameQuery)) {
        continue;
      }

      /// 2️⃣ Fetch OPDs for this doctor
      final opdSnapshot = await _firestore
          .collection('doctors')
          .doc(doctorDoc.id)
          .collection('physical_opds')
          .get();

      if (opdSnapshot.docs.isEmpty) continue;

      /// 🔹 CITY + DEPARTMENT FILTER (local)
      bool opdMatched = false;

      for (final opd in opdSnapshot.docs) {
        final opdData = opd.data() as Map<String, dynamic>;

        final opdCity =
        (opdData['city'] ?? '').toString().toLowerCase();
        final opdDept =
        (opdData['department'] ?? '').toString().toLowerCase();

        final cityMatch =
            cityQuery.isEmpty || opdCity.contains(cityQuery);

        final deptMatch =
            deptQuery.isEmpty || opdDept.contains(deptQuery);

        if (cityMatch && deptMatch) {
          opdMatched = true;
          break;
        }
      }

      if (opdMatched) {
        resultDoctors.add(doctorDoc);
      }
    }

    return resultDoctors;
  }
}
