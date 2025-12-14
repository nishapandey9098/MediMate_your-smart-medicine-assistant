// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 🔑 CRITICAL: Refresh user token when email is verified
 * This ensures Firestore rules work immediately
 */
exports.refreshTokenOnEmailVerification = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const email = user.email;

  console.log(`New user created: ${email} (${uid})`);

  // Set custom claim immediately (will be updated when verified)
  try {
    await admin.auth().setCustomUserClaims(uid, {
      emailVerified: false,
      createdAt: Date.now(),
    });
    console.log(`✅ Initial claims set for ${email}`);
  } catch (error) {
    console.error(`❌ Error setting claims: ${error}`);
  }
});

/**
 * 🔑 CRITICAL: Update token claims when user document changes
 * Firestore trigger that refreshes token when email_verified changes
 */
exports.updateTokenOnVerification = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const userId = context.params.userId;
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Check if we need to update claims
      try {
        const user = await admin.auth().getUser(userId);

        // Update custom claims to match current verification status
        await admin.auth().setCustomUserClaims(userId, {
          emailVerified: user.emailVerified,
          updatedAt: Date.now(),
        });

        console.log(`✅ Token claims updated for user ${userId}: emailVerified=${user.emailVerified}`);

        // Force token refresh by updating a field in Firestore
        await admin.firestore()
            .collection("users")
            .doc(userId)
            .update({
              tokenRefreshedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
      } catch (error) {
        console.error(`❌ Error updating token claims: ${error}`);
      }
    });

/**
 * 🔑 NEW: Check and update verification status
 * Call this from the app to force a check
 */
exports.checkEmailVerification = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const uid = context.auth.uid;

  try {
    // Get fresh user data from Firebase Auth
    const user = await admin.auth().getUser(uid);

    console.log(`Checking verification for ${user.email}: ${user.emailVerified}`);

    // Update custom claims
    await admin.auth().setCustomUserClaims(uid, {
      emailVerified: user.emailVerified,
      checkedAt: Date.now(),
    });

    // Update Firestore document
    await admin.firestore()
        .collection("users")
        .doc(uid)
        .update({
          emailVerified: user.emailVerified,
          lastVerificationCheck: admin.firestore.FieldValue.serverTimestamp(),
        });

    return {
      success: true,
      emailVerified: user.emailVerified,
      message: user.emailVerified ?
        "Email is verified!" :
        "Email not verified yet",
    };
  } catch (error) {
    console.error(`❌ Error checking verification: ${error}`);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
