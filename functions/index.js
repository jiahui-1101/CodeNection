const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const twilio = require("twilio");
const { onRequest } = require("firebase-functions/v2/https");

// Final deployment on xixi
initializeApp();
setGlobalOptions({ region: "asia-southeast1" });

// Twilio Secrets
const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioPhoneNumber = defineSecret("TWILIO_PHONE_NUMBER");

/**
 * ==========================
 * Firestore triggers (unchanged)
 * ==========================
 */
exports.notifyGuardOnNewAlert = onDocumentCreated(
  {
    document: "alerts/{alertId}",
    secrets: [twilioAccountSid, twilioAuthToken, twilioPhoneNumber],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return console.log("No data associated with the event");

    const alertData = snap.data();
    const alertId = event.params.alertId;

    const topic = "new_alerts";
    const payloadForGuards = {
      topic,
      notification: {
        title: "⚠️ Emergency Alert!",
        body: alertData.title || "A new emergency has been reported near you.",
      },
      data: {
        alertId,
        guardId: "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        notificationType: "NEW_ALERT",
      },
      android: { notification: { sound: "default" } },
      apns: { payload: { aps: { sound: "default" } } },
    };

    try {
      const response = await getMessaging().send(payloadForGuards);
      console.log("Successfully sent NEW_ALERT notification for alert:", alertId, "Response:", response);
    } catch (error) {
      console.error("Error sending NEW_ALERT notification:", alertId, "Error:", error);
    }

    if (alertData.emergencyContacts && alertData.emergencyContacts.length > 0) {
      try {
        const client = twilio(twilioAccountSid.value().trim(), twilioAuthToken.value().trim());

        const smsPromises = alertData.emergencyContacts
          .map((contact) => {
            if (contact && contact.phone && contact.phone.startsWith("+")) {
              const messageBody = `URGENT: ${alertData.userName || "Your contact"} has triggered an SOS alert. Please try to contact them immediately. This is an automated message.`;
              console.log(`Preparing SMS to ${contact.name} at ${contact.phone}`);
              return client.messages.create({
                body: messageBody,
                from: twilioPhoneNumber.value().trim(),
                to: contact.phone,
              });
            } else {
              console.warn(`Skipping invalid or missing phone number for contact: ${contact ? contact.name : "Unknown"}`);
              return null;
            }
          })
          .filter(Boolean);

        if (smsPromises.length > 0) {
          await Promise.all(smsPromises);
          console.log("Successfully sent SMS to all valid emergency contacts for alert:", alertId);
        }
      } catch (error) {
        console.error("Error sending SMS to emergency contacts:", error);
      }
    } else {
      console.log("No emergency contacts found for alert:", alertId);
    }
  }
);

exports.notifyUserOnGuardAccept = onDocumentUpdated("alerts/{alertId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const alertId = event.params.alertId;

  if (beforeData.guardId == null && afterData.guardId != null) {
    const userToken = afterData.userFcmToken;
    if (!userToken) return console.log("User FCM token not found for alert:", alertId);

    const payload = {
      token: userToken,
      notification: {
        title: "✅ Help is on the way!",
        body: "A guard has accepted your alert and is en route.",
      },
      data: {
        alertId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        notificationType: "GUARD_ACCEPTED",
      },
    };

    try {
      await getMessaging().send(payload);
      console.log("Successfully sent GUARD_ACCEPTED notification to user for alert:", alertId);
    } catch (error) {
      console.error("Error sending GUARD_ACCEPTED notification:", error);
    }
  }
});

/**
 * ==========================
 * DEBUG Endpoint: Test Twilio Secrets
 * ==========================
 */
exports.testTwilioSecrets = onRequest(
  { secrets: [twilioAccountSid, twilioAuthToken, twilioPhoneNumber] },
  (req, res) => {
    res.json({
      sidPrefix: twilioAccountSid.value()?.substring(0, 5) || "MISSING",
      tokenLength: twilioAuthToken.value()?.length || "MISSING",
      phone: twilioPhoneNumber.value() || "MISSING",
    });
  }
);
