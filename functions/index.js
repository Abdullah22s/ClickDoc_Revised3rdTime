const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

exports.deleteExpiredOnlineClinics = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Asia/Karachi",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    console.log("Checking expired online clinics...");

    const doctorsSnap = await db.collection("doctors").get();

    for (const doctorDoc of doctorsSnap.docs) {
      const onlineClinicsRef = doctorDoc.ref.collection("online_clinics");

      const expiredClinicsSnap = await onlineClinicsRef
        .where("endDateTime", "<=", now)
        .get();

      for (const clinicDoc of expiredClinicsSnap.docs) {
        console.log(`Deleting expired clinic: ${clinicDoc.ref.path}`);

        await deleteClinicWithAppointments(clinicDoc.ref);
      }
    }

    console.log("Expired online clinic cleanup completed.");
  }
);

async function deleteClinicWithAppointments(clinicRef) {
  while (true) {
    const appointmentsSnap = await clinicRef
      .collection("appointments")
      .limit(400)
      .get();

    if (appointmentsSnap.empty) {
      break;
    }

    for (const appointmentDoc of appointmentsSnap.docs) {
      await deleteSubCollection(appointmentDoc.ref.collection("callerCandidates"));
      await deleteSubCollection(appointmentDoc.ref.collection("calleeCandidates"));
    }

    const batch = db.batch();

    appointmentsSnap.docs.forEach((appointmentDoc) => {
      batch.delete(appointmentDoc.ref);
    });

    await batch.commit();
  }

  await clinicRef.delete();
}

async function deleteSubCollection(collectionRef) {
  while (true) {
    const snap = await collectionRef.limit(400).get();

    if (snap.empty) {
      break;
    }

    const batch = db.batch();

    snap.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  }
}