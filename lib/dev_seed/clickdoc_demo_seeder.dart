import 'package:cloud_firestore/cloud_firestore.dart';

class ClickDocDemoSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String doctorUid = 'aGNc9u3B72WHXuI20uPCQpnv2cE2';
  static const String doctorEmail = 'azlan.ali12812@gmail.com';

  static const String patientUid = 'NFxhmJ1j1PfQbBCRI9z4mWHCZqp2';
  static const String patientEmail = 'hbatravelspk@gmail.com';

  static const String dummyPatientOneId = 'demo_patient_001';
  static const String dummyPatientTwoId = 'demo_patient_002';

  static Future<void> seed() async {
    final now = DateTime.now();

    final onlineStartOne = now.add(const Duration(minutes: 10));
    final onlineEndOne = onlineStartOne.add(const Duration(minutes: 15));

    final onlineStartTwo = onlineEndOne.add(const Duration(minutes: 5));
    final onlineEndTwo = onlineStartTwo.add(const Duration(minutes: 15));

    final physicalStartOne = now.add(const Duration(minutes: 15));
    final physicalEndOne = physicalStartOne.add(const Duration(minutes: 15));

    final physicalStartTwo = physicalEndOne.add(const Duration(minutes: 5));
    final physicalEndTwo = physicalStartTwo.add(const Duration(minutes: 15));

    final today = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    final doctorRef = _db.collection('doctors').doc(doctorUid);
    final realPatientRef = _db.collection('patients').doc(patientUid);
    final dummyPatientOneRef = _db.collection('patients').doc(dummyPatientOneId);
    final dummyPatientTwoRef = _db.collection('patients').doc(dummyPatientTwoId);

    final onlineClinicRef = doctorRef.collection('online_clinics').doc('demo_online_clinic_1');
    final physicalOpdRef = doctorRef.collection('physical_opds').doc('demo_physical_opd_1');

    final batch = _db.batch();

    batch.set(
      doctorRef,
      {
        'name': 'Ansu1234',
        'email': doctorEmail,
        'experience': '8 years',
        'licenseNumber': 'PMDC-DEMO-12345',
        'phone': '03001234567',
        'qualifications': ['MD', 'FCPS'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      realPatientRef,
      {
        'name': 'HBA TRAVELS',
        'email': patientEmail,
        'phoneNumber': '923162724750',
        'age': '22',
        'weight': '85',
        'gender': 'Male',
        'bloodGroup': 'AB+',
        'medicalHistory': ['Migraine'],
        'referenceNumber': 'E5U53',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      dummyPatientOneRef,
      {
        'name': 'Ali Raza',
        'email': 'ali.raza.demo@clickdoc.com',
        'phoneNumber': '923001112222',
        'age': '28',
        'weight': '74',
        'gender': 'Male',
        'bloodGroup': 'B+',
        'medicalHistory': ['Diabetes'],
        'referenceNumber': 'CD101',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      dummyPatientTwoRef,
      {
        'name': 'Sara Khan',
        'email': 'sara.khan.demo@clickdoc.com',
        'phoneNumber': '923331234567',
        'age': '31',
        'weight': '63',
        'gender': 'Female',
        'bloodGroup': 'O+',
        'medicalHistory': ['Blood Pressure'],
        'referenceNumber': 'CD102',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      onlineClinicRef,
      {
        'department': 'Cardiology',
        'doctorId': doctorUid,
        'doctorName': 'Ansu1234',
        'days': [_dayName(now)],
        'startTime': _time(onlineStartOne),
        'endTime': _time(onlineEndTwo),
        'fees': 1500,
        'appointmentDuration': 15,
        'bufferDuration': 5,
        'startDateTime': Timestamp.fromDate(onlineStartOne),
        'endDateTime': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'slots': [
          {'start': _time(onlineStartOne), 'end': _time(onlineEndOne)},
          {'start': _time(onlineStartTwo), 'end': _time(onlineEndTwo)},
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      onlineClinicRef.collection('appointments').doc('demo_online_pending'),
      {
        'start': _time(onlineStartOne),
        'end': _time(onlineEndOne),
        'status': 'pending',
        'patientId': dummyPatientOneId,
        'patientReference': 'CD101',
        'doctorName': 'Ansu1234',
        'department': 'Cardiology',
        'fees': 1500,
        'vitalsEntered': false,
        'startDateTime': Timestamp.fromDate(onlineStartOne),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      onlineClinicRef.collection('appointments').doc('demo_online_ready'),
      {
        'start': _time(onlineStartTwo),
        'end': _time(onlineEndTwo),
        'status': 'accepted',
        'patientId': patientUid,
        'patientReference': 'E5U53',
        'doctorName': 'Ansu1234',
        'department': 'Cardiology',
        'fees': 1500,
        'vitalsEntered': true,
        'vitals': {
          'bp': '120/80',
          'temp': '98.6',
          'spo2': '98',
        },
        'startDateTime': Timestamp.fromDate(onlineStartTwo),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      physicalOpdRef,
      {
        'hospitalName': 'Demo City Hospital',
        'department': 'Cardiology',
        'doctorId': doctorUid,
        'days': [_dayName(now)],
        'startTime': _time(physicalStartOne),
        'endTime': _time(physicalEndTwo),
        'fees': 1200,
        'appointmentDuration': 15,
        'bufferDuration': 5,
        'startDateTime': Timestamp.fromDate(physicalStartOne),
        'endDateTime': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'slots': [
          {'start': _time(physicalStartOne), 'end': _time(physicalEndOne)},
          {'start': _time(physicalStartTwo), 'end': _time(physicalEndTwo)},
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      physicalOpdRef.collection('appointments').doc('demo_physical_waiting_vitals'),
      {
        'start': _time(physicalStartOne),
        'end': _time(physicalEndOne),
        'status': 'accepted',
        'patientId': patientUid,
        'patientReference': 'E5U53',
        'doctorName': 'Ansu1234',
        'department': 'Cardiology',
        'fees': 1200,
        'vitalsEntered': false,
        'startDateTime': Timestamp.fromDate(physicalStartOne),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      physicalOpdRef.collection('appointments').doc('demo_physical_ready'),
      {
        'start': _time(physicalStartTwo),
        'end': _time(physicalEndTwo),
        'status': 'accepted',
        'patientId': dummyPatientTwoId,
        'patientReference': 'CD102',
        'doctorName': 'Ansu1234',
        'department': 'Cardiology',
        'fees': 1200,
        'vitalsEntered': true,
        'vitals': {
          'bp': '130/85',
          'temp': '98.4',
          'spo2': '99',
        },
        'startDateTime': Timestamp.fromDate(physicalStartTwo),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _db.collection('doctor_patient_history').doc('demo_history_real_patient_today'),
      {
        'doctorId': doctorUid,
        'patientId': patientUid,
        'referenceNumber': 'E5U53',
        'department': 'Cardiology',
        'appointmentDate': Timestamp.fromDate(today),
        'slotStart': _time(onlineStartTwo),
        'slotEnd': _time(onlineEndTwo),
        'acceptedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    batch.set(
      _db.collection('doctor_patient_history').doc('demo_history_dummy_patient_1_today'),
      {
        'doctorId': doctorUid,
        'patientId': dummyPatientOneId,
        'referenceNumber': 'CD101',
        'department': 'General Medicine',
        'appointmentDate': Timestamp.fromDate(today),
        'slotStart': _time(onlineStartOne),
        'slotEnd': _time(onlineEndOne),
        'acceptedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    batch.set(
      _db.collection('doctor_patient_history').doc('demo_history_dummy_patient_2_today'),
      {
        'doctorId': doctorUid,
        'patientId': dummyPatientTwoId,
        'referenceNumber': 'CD102',
        'department': 'Cardiology',
        'appointmentDate': Timestamp.fromDate(today),
        'slotStart': _time(physicalStartTwo),
        'slotEnd': _time(physicalEndTwo),
        'acceptedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    batch.set(
      realPatientRef.collection('prescriptions').doc('demo_prescription_1'),
      {
        'doctorId': doctorUid,
        'createdAt': FieldValue.serverTimestamp(),
        'prescriptionText':
        'Tab Panadol 500mg twice daily after meal for 3 days. Drink water and follow up if symptoms continue.',
        'prescriptionImageUrl': null,
      },
      SetOptions(merge: true),
    );

    batch.set(
      realPatientRef.collection('prescriptions').doc('demo_prescription_2'),
      {
        'doctorId': doctorUid,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'prescriptionText':
        'Check blood pressure daily. Avoid oily food. Follow up after one week.',
        'prescriptionImageUrl': null,
      },
      SetOptions(merge: true),
    );

    batch.set(
      realPatientRef.collection('online_vitals_history').doc('demo_online_ready'),
      {
        'appointmentId': 'demo_online_ready',
        'sourceAppointmentPath':
        'doctors/$doctorUid/online_clinics/demo_online_clinic_1/appointments/demo_online_ready',
        'patientId': patientUid,
        'doctorId': doctorUid,
        'doctorName': 'Ansu1234',
        'clinicId': 'demo_online_clinic_1',
        'vitals': {
          'bp': '120/80',
          'temp': '98.6',
          'spo2': '98',
        },
        'appointmentDate': Timestamp.fromDate(onlineStartTwo),
        'vitalsEnteredAt': FieldValue.serverTimestamp(),
        'type': 'online',
      },
      SetOptions(merge: true),
    );

    batch.set(
      realPatientRef.collection('physical_vitals_history').doc('demo_physical_old'),
      {
        'appointmentId': 'demo_physical_old',
        'sourceAppointmentPath':
        'doctors/$doctorUid/physical_opds/demo_physical_opd_1/appointments/demo_physical_ready',
        'patientId': patientUid,
        'doctorId': doctorUid,
        'doctorName': 'Ansu1234',
        'clinicId': 'demo_physical_opd_1',
        'vitals': {
          'bp': '118/78',
          'temp': '98.5',
          'spo2': '99',
        },
        'appointmentDate': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'vitalsEnteredAt': FieldValue.serverTimestamp(),
        'type': 'physical',
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static String _time(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _dayName(DateTime dateTime) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dateTime.weekday - 1];
  }
}