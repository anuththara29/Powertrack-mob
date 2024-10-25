const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://powerprox-project-default-rtdb.firebaseio.com/",
});

exports.notifyOnBusChange = functions.database.ref("/HQ")
    .onUpdate((change, context) => {
      const afterData = change.after.val();
      const BusA = afterData.BusA;
      const BusB = afterData.BusB;

      // Check if either BusA or BusB is "0"
      if (BusA === "0" || BusB === "0") {
        const payload = {
          notification: {
            title: "Bus Status Alert",
            body: `BusA or BusB is now 0!`,
          },
          token: "cz9XyxGYTMqBUL1jkLX6Db:APA91bELz4-EmBWd41dEsyeBjeQJh1DB92QtXuWwyHqcJLjy4kPHJIUEhchAZrCil4OHPzaPvmLFfpxkw0s5mWWGe9BZ6UOOgBmoek8BsM1jjYj_2uANQz6L-6x6PjY0teNPlKZFx2h3",
        };

        return admin.messaging().send(payload)
            .then((response) => {
              console.log("Successfully sent message:", response);
              return null;
            })
            .catch((error) => {
              console.error("Error sending message:", error);
              return null;
            });
      } else {
        return null;
      }
    });
