// Cloud Function to set admin custom claims
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // Check if request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  // Check if the current user is already an admin (you might want to hardcode initial admin)
  const currentUserRecord = await admin.auth().getUser(context.auth.uid);
  const isCurrentUserAdmin = currentUserRecord.customClaims?.admin === true;

  if (!isCurrentUserAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Must be admin to set admin claims');
  }

  const { uid, isAdmin } = data;

  try {
    // Set custom claims
    await admin.auth().setCustomUserClaims(uid, { admin: isAdmin });
    
    // Also update Firestore document
    await admin.firestore().collection('users').doc(uid).update({
      isAdmin: isAdmin,
      role: isAdmin ? 'admin' : 'user'
    });

    return { success: true, message: `Admin claim ${isAdmin ? 'granted' : 'revoked'} for user ${uid}` };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Error setting admin claim');
  }
});
