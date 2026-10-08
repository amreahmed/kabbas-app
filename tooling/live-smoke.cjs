// Creates only a disposable test account and its own test data; cleans up on exit.
const {readFileSync} = require('node:fs');
const {randomUUID, randomBytes} = require('node:crypto');
const {initializeApp, deleteApp} = require('firebase/app');
const {getAuth, createUserWithEmailAndPassword, deleteUser} = require('firebase/auth');
const {getFirestore, doc, setDoc, getDocs, collection, query, where, updateDoc, deleteDoc, serverTimestamp, terminate} = require('firebase/firestore');
async function main() {
  const config = JSON.parse(readFileSync('android/app/google-services.json'));
  const client = config.client.find(c => c.client_info.android_client_info.package_name === 'com.kabbas.app');
  const app = initializeApp({apiKey:client.api_key[0].current_key, appId:client.client_info.mobilesdk_app_id, projectId:config.project_info.project_id});
  const auth = getAuth(app), db = getFirestore(app);
  const isPipeInstallation = process.argv.includes('--pipe-installation');
  const orderCollection = isPipeInstallation ? 'pipe_installation_orders' : 'maintenance_orders';
  let user, profile, orderRef;
  try {
    ({user} = await createUserWithEmailAndPassword(auth, `release-test-${randomUUID()}@example.com`, randomBytes(24).toString('hex')));
    profile = doc(db,'users',user.uid);
    orderRef = doc(db,orderCollection,`release-test-${randomUUID()}`);
    await setDoc(profile,{name:'Release verification',email:user.email,role:'user',createdAt:serverTimestamp()});
    await setDoc(orderRef,{clientName:'Release verification',clientPhone:'01000000000',userId:user.uid,userEmail:user.email,status:'جديد',createdAt:serverTimestamp(),description:'Disposable automated deployment check', ...(isPipeInstallation ? {serviceType:'تأسيس مواسير التكييفات',address:'عنوان اختبار مؤقت - لا يحتاج لتنفيذ',unitCount:1} : {})});
    const own = await getDocs(query(collection(db,orderCollection),where('userId','==',user.uid)));
    if (own.size !== 1) throw new Error('Own order query failed');
    try { await getDocs(collection(db,orderCollection)); throw new Error('Cross-user query was allowed'); }
    catch (e) { if (e.code !== 'permission-denied') throw e; }
    try { await updateDoc(profile,{role:'admin'}); throw new Error('Role escalation was allowed'); }
    catch (e) { if (e.code !== 'permission-denied') throw e; }
    await updateDoc(profile,{deletionRequestedAt:serverTimestamp()});
    await deleteDoc(orderRef); orderRef = null;
    await deleteDoc(profile); profile = null;
    await deleteUser(user); user = null;
    console.log(`PASS: ${orderCollection}: live registration, profile, order creation, own-order query, privacy isolation, role protection and account/data deletion.`);
  } finally {
    if (orderRef) await deleteDoc(orderRef);
    if (profile) await deleteDoc(profile);
    if (user) await deleteUser(user);
    await terminate(db);
    await deleteApp(app);
  }
}
main().catch(e => {console.error(e.code || e.message); process.exitCode = 1;});
