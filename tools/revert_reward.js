// revert_reward.js
// Usage: node revert_reward.js "users/{uid}/rewards/{rewardId}"
// Requires: npm install firebase-admin
// Set env var GOOGLE_APPLICATION_CREDENTIALS to your service account JSON

const admin = require('firebase-admin');
const path = require('path');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('ERROR: set GOOGLE_APPLICATION_CREDENTIALS to the service account JSON path');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function revertReward(rewardPath) {
  const rewardRef = db.doc(rewardPath);

  await db.runTransaction(async (tx) => {
    const rewardSnap = await tx.get(rewardRef);
    if (!rewardSnap.exists) {
      throw new Error(`Reward not found: ${rewardPath}`);
    }

    const reward = rewardSnap.data();
    if (!reward.used) {
      throw new Error(`Reward is already unused: ${rewardPath}`);
    }

    const ownerUid = reward.ownerUid || (() => {
      // try to parse owner from path as fallback
      const m = rewardPath.match(/^users\/([^\/]+)\/rewards\//);
      return m ? m[1] : null;
    })();

    if (!ownerUid) {
      throw new Error('Cannot determine owner UID for reward');
    }

    const userRef = db.doc(`users/${ownerUid}`);
    const points = (typeof reward.points === 'number') ? reward.points : 0;

    // Find matching claim docs under users/{uid}/claims where rewardRef == rewardRef
    const claimsCol = userRef.collection('claims');
    const claimsQuery = await tx.get(claimsCol.where('rewardRef', '==', rewardRef));

    // Delete all matching claim docs
    for (const claimDoc of claimsQuery.docs) {
      tx.delete(claimDoc.ref);
    }

    // Update reward: used=false, remove redeemedAt (set to null/remove), keep other fields
    tx.update(rewardRef, {
      used: false,
      redeemedAt: admin.firestore.FieldValue.delete(),
    });

    // Restore user points
    tx.update(userRef, {
      totalPoints: admin.firestore.FieldValue.increment(points),
    });

    console.log(`Queued revert: reward ${rewardPath}, +${points} points to users/${ownerUid}, deleted ${claimsQuery.size} claim(s)`);
  });

  console.log('Transaction committed successfully');
}

async function main() {
  const arg = process.argv[2];
  if (!arg) {
    console.error('Usage: node revert_reward.js "users/{uid}/rewards/{rewardId}"');
    process.exit(1);
  }

  try {
    await revertReward(arg);
  } catch (err) {
    console.error('Error:', err.message || err);
    process.exit(1);
  }
}

main();
