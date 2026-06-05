const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ============================================================
// 🔔 ClickDoc FCM notification helpers
// ============================================================
function cleanStringMap(data = {}) {
  const result = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) continue;
    result[key] = String(value);
  }
  return result;
}

function extractTokens(data = {}) {
  const tokens = [];

  if (typeof data.fcmToken === "string") tokens.push(data.fcmToken);
  if (typeof data.patient_token === "string") tokens.push(data.patient_token);
  if (typeof data.patientFcmToken === "string") tokens.push(data.patientFcmToken);
  if (typeof data.token === "string") tokens.push(data.token);

  if (Array.isArray(data.fcmTokens)) {
    data.fcmTokens.forEach((token) => {
      if (typeof token === "string") tokens.push(token);
    });
  }

  return [...new Set(tokens.filter((token) => token && token.trim() !== ""))];
}

async function getUserTokens(collection, docId) {
  if (!collection || !docId) return [];
  const snap = await db.collection(collection).doc(docId).get();
  if (!snap.exists) return [];
  return extractTokens(snap.data() || {});
}

async function addNotificationDoc({
  recipientCollection,
  recipientId,
  title,
  body,
  type,
  refPath,
  extraData = {},
}) {
  if (!recipientCollection || !recipientId) return;

  await db.collection("notifications").add({
    recipientCollection,
    recipientId,
    title,
    body,
    type,
    refPath,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    data: cleanStringMap(extraData),
  });
}

async function sendPush({
  tokens,
  title,
  body,
  type,
  refPath,
  extraData = {},
}) {
  const uniqueTokens = [...new Set((tokens || []).filter(Boolean))];
  if (uniqueTokens.length === 0) {
    console.log(`No FCM token found for: ${title}`);
    return null;
  }

  const data = cleanStringMap({
    title,
    body,
    type,
    refPath,
    ...extraData,
  });

  // FCM multicast supports up to 500 tokens per call.
  const batches = [];
  for (let i = 0; i < uniqueTokens.length; i += 500) {
    batches.push(uniqueTokens.slice(i, i + 500));
  }

  const responses = [];
  for (const batchTokens of batches) {
    console.log(
      "FCM_TARGET_DEBUG=" +
        JSON.stringify({
          title,
          tokenCount: batchTokens.length,
          firstTokenStart: batchTokens[0]
            ? batchTokens[0].substring(0, 30)
            : "NO_TOKEN",
          firstTokenLength: batchTokens[0] ? batchTokens[0].length : 0,
        })
    );
    const response = await messaging.sendEachForMulticast({
      tokens: batchTokens,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: {
          channelId: "clickdoc_alerts",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    responses.push(response);

    console.log(
      `Push sent: ${title}. Success=${response.successCount}, Failure=${response.failureCount}`
    );

    if (response.failureCount > 0) {
      response.responses.forEach((item, index) => {
        if (!item.success) {
          const errorInfo = {
            title,
            tokenIndex: index,
            tokenStart: batchTokens[index]
              ? batchTokens[index].substring(0, 30)
              : "NO_TOKEN",
            tokenLength: batchTokens[index] ? batchTokens[index].length : 0,
            errorCode: item.error ? item.error.code : "NO_ERROR_CODE",
            errorMessage: item.error ? item.error.message : "NO_ERROR_MESSAGE",
          };

          console.log("FCM_SEND_FAILED_JSON=" + JSON.stringify(errorInfo));
        }
      });
    }
  }

  return responses;
}

function appointmentBody(prefix, data = {}) {
  const start = data.start || data.slotStart || "";
  const end = data.end || data.slotEnd || "";
  const reference = data.patientReference || data.referenceNumber || "Patient";
  const timeText = start && end ? ` (${start} - ${end})` : "";
  return `${prefix}: ${reference}${timeText}`;
}

async function notifyPatientFromAppointment({
  data,
  title,
  body,
  type,
  refPath,
  extraData = {},
}) {
  let tokens = extractTokens(data);

  if (tokens.length === 0 && data.patientId) {
    tokens = await getUserTokens("patients", data.patientId);
  }

  await sendPush({ tokens, title, body, type, refPath, extraData });

  if (data.patientId) {
    await addNotificationDoc({
      recipientCollection: "patients",
      recipientId: data.patientId,
      title,
      body,
      type,
      refPath,
      extraData,
    });
  }
}

async function notifyDoctorOfNewAppointment({
  doctorId,
  appointmentData,
  appointmentType,
  appointmentPath,
}) {
  const tokens = await getUserTokens("doctors", doctorId);
  const title = appointmentType === "online"
    ? "New online appointment request"
    : "New physical appointment request";
  const body = appointmentBody("Booking request received", appointmentData);

  await sendPush({
    tokens,
    title,
    body,
    type: `${appointmentType}_appointment_booked`,
    refPath: appointmentPath,
    extraData: {
      doctorId,
      patientId: appointmentData.patientId || "",
      appointmentType,
    },
  });

  await addNotificationDoc({
    recipientCollection: "doctors",
    recipientId: doctorId,
    title,
    body,
    type: `${appointmentType}_appointment_booked`,
    refPath: appointmentPath,
    extraData: {
      doctorId,
      patientId: appointmentData.patientId || "",
      appointmentType,
    },
  });
}

async function handleAppointmentStatusChange({
  before,
  after,
  appointmentType,
  refPath,
}) {
  const oldStatus = before.status;
  const newStatus = after.status;

  if (oldStatus === newStatus) return;

  let title = "Appointment update";
  let body = "Your appointment status has changed.";

  if (newStatus === "accepted") {
    title = appointmentType === "online"
      ? "Online appointment accepted"
      : "Physical appointment accepted";
    body = appointmentType === "online"
      ? "Your appointment has been accepted. Please enter your vitals before the call."
      : "Your physical appointment has been accepted. Please provide your vitals at the clinic.";
  } else if (newStatus === "in_progress") {
    title = "Appointment started";
    body = appointmentType === "online"
      ? "Your doctor has started the online appointment. Join the video call."
      : "Your doctor has started your appointment.";
  } else if (newStatus === "rejected") {
    title = "Appointment rejected";
    body = "Your appointment request was rejected.";
  } else if (newStatus === "completed") {
    title = "Appointment completed";
    body = "Your appointment has been completed.";
  } else {
    return;
  }

  await notifyPatientFromAppointment({
    data: after,
    title,
    body,
    type: `${appointmentType}_appointment_${newStatus}`,
    refPath,
    extraData: {
      appointmentType,
      oldStatus: oldStatus || "",
      newStatus: newStatus || "",
      doctorId: after.doctorId || "",
      patientId: after.patientId || "",
    },
  });
}

async function handleAppointmentDeleted({
  before,
  appointmentType,
  refPath,
}) {
  const oldStatus = before.status;

  let title = null;
  let body = null;
  let type = null;

  if (oldStatus === "pending") {
    title = "Appointment rejected";
    body = "Your appointment request was rejected.";
    type = `${appointmentType}_appointment_rejected`;
  } else if (oldStatus === "in_progress") {
    title = "Appointment completed";
    body = "Your appointment has been completed.";
    type = `${appointmentType}_appointment_completed`;
  } else if (oldStatus === "accepted") {
    title = "Appointment cancelled";
    body = "Your appointment was cancelled.";
    type = `${appointmentType}_appointment_cancelled`;
  }

  if (!title || !body || !type) return;

  await notifyPatientFromAppointment({
    data: before,
    title,
    body,
    type,
    refPath,
    extraData: {
      appointmentType,
      oldStatus: oldStatus || "",
      patientId: before.patientId || "",
    },
  });
}

// ============================================================
// 🩺 Appointment notifications
// ============================================================
exports.notifyDoctorOnOnlineAppointmentBooked = onDocumentCreated(
  "doctors/{doctorId}/online_clinics/{clinicId}/appointments/{appointmentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    await notifyDoctorOfNewAppointment({
      doctorId: event.params.doctorId,
      appointmentData: snap.data() || {},
      appointmentType: "online",
      appointmentPath: snap.ref.path,
    });
  }
);

exports.notifyDoctorOnPhysicalAppointmentBooked = onDocumentCreated(
  "doctors/{doctorId}/physical_opds/{clinicId}/appointments/{appointmentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    await notifyDoctorOfNewAppointment({
      doctorId: event.params.doctorId,
      appointmentData: snap.data() || {},
      appointmentType: "physical",
      appointmentPath: snap.ref.path,
    });
  }
);

exports.notifyPatientOnOnlineAppointmentStatus = onDocumentUpdated(
  "doctors/{doctorId}/online_clinics/{clinicId}/appointments/{appointmentId}",
  async (event) => {
    if (!event.data) return;
    await handleAppointmentStatusChange({
      before: event.data.before.data() || {},
      after: event.data.after.data() || {},
      appointmentType: "online",
      refPath: event.data.after.ref.path,
    });
  }
);

exports.notifyPatientOnPhysicalAppointmentStatus = onDocumentUpdated(
  "doctors/{doctorId}/physical_opds/{clinicId}/appointments/{appointmentId}",
  async (event) => {
    if (!event.data) return;
    await handleAppointmentStatusChange({
      before: event.data.before.data() || {},
      after: event.data.after.data() || {},
      appointmentType: "physical",
      refPath: event.data.after.ref.path,
    });
  }
);

exports.notifyPatientOnOnlineAppointmentDeleted = onDocumentDeleted(
  "doctors/{doctorId}/online_clinics/{clinicId}/appointments/{appointmentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    await handleAppointmentDeleted({
      before: snap.data() || {},
      appointmentType: "online",
      refPath: snap.ref.path,
    });
  }
);

exports.notifyPatientOnPhysicalAppointmentDeleted = onDocumentDeleted(
  "doctors/{doctorId}/physical_opds/{clinicId}/appointments/{appointmentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    await handleAppointmentDeleted({
      before: snap.data() || {},
      appointmentType: "physical",
      refPath: snap.ref.path,
    });
  }
);

exports.notifyPatientOnPrescriptionAdded = onDocumentCreated(
  "patients/{patientId}/prescriptions/{prescriptionId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const patientId = event.params.patientId;
    const tokens = await getUserTokens("patients", patientId);

    const title = "Prescription added";
    const body = "Your doctor has added a prescription to your profile.";

    await sendPush({
      tokens,
      title,
      body,
      type: "prescription_added",
      refPath: snap.ref.path,
      extraData: { patientId },
    });

    await addNotificationDoc({
      recipientCollection: "patients",
      recipientId: patientId,
      title,
      body,
      type: "prescription_added",
      refPath: snap.ref.path,
      extraData: { patientId },
    });
  }
);

// ============================================================
// 🚑 SOS / ambulance notifications
// ============================================================
exports.notifyNearbyAmbulancesOnSOS = onDocumentCreated(
  "emergency_requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    const ambulanceIds = Array.isArray(data.nearbyAmbulances)
      ? data.nearbyAmbulances
      : [];

    if (ambulanceIds.length === 0) {
      console.log("SOS created, but no nearby ambulances found.");
      return;
    }

    const title = "Emergency SOS nearby";
    const body = "A nearby patient needs ambulance support. Open ClickDoc to respond.";

    for (const ambulanceId of ambulanceIds) {
      const tokens = await getUserTokens("ambulances", ambulanceId);

      await sendPush({
        tokens,
        title,
        body,
        type: "sos_created",
        refPath: snap.ref.path,
        extraData: {
          requestId: event.params.requestId,
          patientId: data.patientId || "",
        },
      });

      await addNotificationDoc({
        recipientCollection: "ambulances",
        recipientId: ambulanceId,
        title,
        body,
        type: "sos_created",
        refPath: snap.ref.path,
        extraData: {
          requestId: event.params.requestId,
          patientId: data.patientId || "",
        },
      });
    }
  }
);

exports.notifyPatientWhenAmbulanceAssigned = onDocumentUpdated(
  "emergency_requests/{requestId}",
  async (event) => {
    if (!event.data) return;

    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    if (before.status === after.status) return;
    if (after.status !== "accepted") return;

    let tokens = extractTokens(after);
    if (tokens.length === 0 && after.patientId) {
      tokens = await getUserTokens("patients", after.patientId);
    }

    const title = "Ambulance assigned";
    const body = "An ambulance has accepted your SOS request. Live tracking is now available.";

    await sendPush({
      tokens,
      title,
      body,
      type: "ambulance_assigned",
      refPath: event.data.after.ref.path,
      extraData: {
        requestId: event.params.requestId,
        patientId: after.patientId || "",
        assignedAmbulance: after.assignedAmbulance || after.acceptedBy || "",
      },
    });

    if (after.patientId) {
      await addNotificationDoc({
        recipientCollection: "patients",
        recipientId: after.patientId,
        title,
        body,
        type: "ambulance_assigned",
        refPath: event.data.after.ref.path,
        extraData: {
          requestId: event.params.requestId,
          patientId: after.patientId || "",
          assignedAmbulance: after.assignedAmbulance || after.acceptedBy || "",
        },
      });
    }
  }
);

// ============================================================
// 🧹 Existing scheduled cleanup function preserved
// ============================================================
exports.deleteExpiredOnlineClinics = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Asia/Karachi",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    console.log("Checking expired online and physical clinics...");

    const doctorsSnap = await db.collection("doctors").get();

    for (const doctorDoc of doctorsSnap.docs) {
      // Delete expired ONLINE clinics
      const onlineClinicsRef = doctorDoc.ref.collection("online_clinics");

      const expiredOnlineClinicsSnap = await onlineClinicsRef
        .where("endDateTime", "<=", now)
        .get();

      for (const clinicDoc of expiredOnlineClinicsSnap.docs) {
        console.log(`Deleting expired online clinic: ${clinicDoc.ref.path}`);
        await deleteClinicWithAppointments(clinicDoc.ref);
      }

      // Delete expired PHYSICAL OPDs
      const physicalOpdsRef = doctorDoc.ref.collection("physical_opds");

      const expiredPhysicalOpdsSnap = await physicalOpdsRef
        .where("endDateTime", "<=", now)
        .get();

      for (const clinicDoc of expiredPhysicalOpdsSnap.docs) {
        console.log(`Deleting expired physical OPD: ${clinicDoc.ref.path}`);
        await deleteClinicWithAppointments(clinicDoc.ref);
      }
    }

    console.log("Expired online and physical clinic cleanup completed.");
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
      await deleteSubCollection(
        appointmentDoc.ref.collection("callerCandidates")
      );

      await deleteSubCollection(
        appointmentDoc.ref.collection("calleeCandidates")
      );
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
