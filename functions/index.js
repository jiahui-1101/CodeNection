const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

/**
 * 这个 function 会在 alerts 集合里有【新文件被创建】时自动触发。
 */
exports.notifyGuardOnNewAlert = onDocumentCreated("alerts/{alertId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        console.log("No data associated with the event");
        return;
    }
    const alertData = snap.data();
    const alertId = event.params.alertId;

    const topic = "new_alerts";

    const payload = {
        notification: {
            title: "⚠️ Emergency Alert!",
            body: alertData.title || "A new emergency has been reported near you.",
            sound: "default",
        },
        data: {
            alertId: alertId,
            guardId: alertData.guardId || "", 
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
    };

    console.log("Constructed payload:", payload);

    try {
        const response = await getMessaging().sendToTopic(topic, payload);
        console.log("Successfully sent notification for alert:", alertId, "Response:", response);
    } catch (error) {
        console.error("Error sending notification for alert:", alertId, "Error:", error);
    }
});


/**
 * 当有 Guard 接单时，再发一个通知给 User。
 */
exports.notifyUserOnGuardAccept = onDocumentUpdated("alerts/{alertId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const alertId = event.params.alertId;

    // 检查是不是 guardId 刚刚被加上去
    if (beforeData.guardId == null && afterData.guardId != null) {
        const userToken = afterData.userFcmToken;

        if (!userToken) {
            console.log("User FCM token not found for alert:", alertId);
            return;
        }

        const payload = {
            notification: {
                title: "✅ Help is on the way!",
                body: "A guard has accepted your alert and is en route.",
            },
            data: {
                alertId: alertId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            }
        };

        try {
            await getMessaging().sendToDevice(userToken, payload);
            console.log("Successfully sent 'Guard Accepted' notification to user for alert:", alertId);
        } catch (error) {
            console.error("Error sending 'Guard Accepted' notification:", error);
        }
    }
});
