const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {setGlobalOptions} = require("firebase-functions/v2");
const {defineSecret} = require("firebase-functions/params");
const twilio = require("twilio");

initializeApp();
setGlobalOptions({region: "asia-southeast1"});

const twilioAccountSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioAuthToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioPhoneNumber = defineSecret("TWILIO_PHONE_NUMBER");


exports.notifyGuardOnNewAlert = onDocumentCreated(
    {
        document: "alerts/{alertId}",
        secrets: [twilioAccountSid, twilioAuthToken, twilioPhoneNumber],
    },
    async (event) => {
        const snap = event.data;
        if (!snap) {
            console.log("No data associated with the event");
            return;
        }
        const alertData = snap.data();
        const alertId = event.params.alertId;


        const topic = "new_alerts";
        const payloadForGuards = {
            topic: topic,
            notification: {
                title: "⚠️ Emergency Alert!",
                body: alertData.title || "A new emergency has been reported near you.",
            },
            data: {
                alertId: alertId,
                guardId: alertData.guardId || "",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: { 
                notification: {
                    sound: "default",
                }
            },
            apns: { 
                payload: {
                    aps: {
                        sound: "default",
                    }
                }
            }
        };

        try {

            const response = await getMessaging().send(payloadForGuards);
            console.log("Successfully sent FCM to guards for alert:", alertId, "Response:", response);
        } catch (error) {
            console.error("Error sending FCM to guards for alert:", alertId, "Error:", error);
        }

        if (alertData.emergencyContacts && alertData.emergencyContacts.length > 0) {
            try {
                const client = twilio(twilioAccountSid.value(), twilioAuthToken.value());
                const smsPromises = alertData.emergencyContacts.map((contact) => {
                    const messageBody = `URGENT: ${alertData.userName || "Your contact"} has triggered an SOS alert. Please try to contact them immediately. This is an automated message.`;
                    console.log(`Preparing SMS to ${contact.name} at ${contact.phone}`);
                    return client.messages.create({
                        body: messageBody,
                        from: twilioPhoneNumber.value(),
                        to: contact.phone,
                    });
                });
                await Promise.all(smsPromises);
                console.log("Successfully sent SMS to all emergency contacts for alert:", alertId);
            } catch (error) {
                console.error("Error sending SMS to emergency contacts:", error);
            }
        } else {
            console.log("No emergency contacts found for alert:", alertId);
        }
    },
);

exports.notifyUserOnGuardAccept = onDocumentUpdated("alerts/{alertId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const alertId = event.params.alertId;

    if (beforeData.guardId == null && afterData.guardId != null) {
        const userToken = afterData.userFcmToken;

        if (!userToken) {
            console.log("User FCM token not found for alert:", alertId);
            return;
        }
        
        const payload = {
            token: userToken, 
            notification: {
                title: "✅ Help is on the way!",
                body: "A guard has accepted your alert and is en route.",
            },
            data: {
                alertId: alertId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
        };

        try {
     
            await getMessaging().send(payload);
            console.log("Successfully sent 'Guard Accepted' notification to user for alert:", alertId);
        } catch (error) {
            console.error("Error sending 'Guard Accepted' notification:", error);
        }
    }
});

