import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search doctors by name or department/specialization
  Future<List<QueryDocumentSnapshot>> searchDoctors(String query) async {
    if (query.isEmpty) {
      final snapshot = await _firestore.collection('doctors').get();
      return snapshot.docs;
    }

    // Case-insensitive search
    final searchTerm = query.trim().toLowerCase();

    // Search by doctor name first
    final nameResults = await _firestore
        .collection('doctors')
        .where('name_lowercase', isGreaterThanOrEqualTo: searchTerm)
        .where('name_lowercase', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .get();

    if (nameResults.docs.isNotEmpty) return nameResults.docs;

    // If no match by name, search by specialization or department
    final allDoctors = await _firestore.collection('doctors').get();
    final filtered = <QueryDocumentSnapshot>[];

    for (var doc in allDoctors.docs) {
      final onlineClinics = await _firestore
          .collection('doctors')
          .doc(doc.id)
          .collection('online_clinics')
          .get();
      final physicalOpds = await _firestore
          .collection('doctors')
          .doc(doc.id)
          .collection('physical_opds')
          .get();

      final matchOnline = onlineClinics.docs.any((c) =>
          c.data().toString().toLowerCase().contains(searchTerm));
      final matchPhysical = physicalOpds.docs.any((c) =>
          c.data().toString().toLowerCase().contains(searchTerm));

      if (matchOnline || matchPhysical) filtered.add(doc);
    }

    return filtered;
  }
}
