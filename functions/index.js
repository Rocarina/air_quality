const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.airQualityAlert = functions.database
    .ref("/air_quality/CO")
    .onUpdate((change, context) => {

        const newValue = change.after.val();

        if (newValue > 50) {

            const payload = {
                notification: {
                    title: "Alert High CO Levels",
                    body: `CO level has exceeded safe limits: ${newValue} ppm. Please take necessary precautions!`,
                }
            };

            return admin.messaging().sendToTopic("air_quality_alerts", payload);
        }

        return null;
    });