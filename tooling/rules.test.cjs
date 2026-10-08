const {test, before, after, beforeEach} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc, serverTimestamp} = require('firebase/firestore');
let env;
before(async () => { env = await initializeTestEnvironment({projectId:'demo-kabbas', firestore: {host:'127.0.0.1', port:8090, rules:readFileSync('firestore.rules','utf8')}}); });
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    await setDoc(doc(db,'users/alice'), {name:'Alice',email:'alice@example.com',role:'user'});
    await setDoc(doc(db,'users/bob'), {name:'Bob',email:'bob@example.com',role:'admin'});
    await setDoc(doc(db,'maintenance_orders/alice-order'), {userId:'alice',userEmail:'alice@example.com',status:'جديد'});
    await setDoc(doc(db,'maintenance_orders/bob-order'), {userId:'bob',userEmail:'bob@example.com',status:'جديد'});
  });
});
const dbFor = (uid, claims={}) => env.authenticatedContext(uid,{email:`${uid}@example.com`,...claims}).firestore();
const order = () => ({userId:'alice',userEmail:'alice@example.com',clientName:'Alice',clientPhone:'01012345678',status:'جديد',createdAt:serverTimestamp()});
test('customers can query only their own orders', async () => {
  const db = dbFor('alice');
  await assertSucceeds(getDocs(query(collection(db,'maintenance_orders'),where('userId','==','alice'))));
  await assertFails(getDocs(collection(db,'maintenance_orders')));
  await assertFails(getDoc(doc(db,'maintenance_orders/bob-order')));
});
test('email and legacy profile role do not grant administrator access', async () => {
  await assertFails(setDoc(doc(dbFor('bob'), 'products/x'),{name:'Forbidden'}));
  await assertFails(setDoc(doc(dbFor('alice',{email:'admin@kabbas.com'}),'products/x'),{name:'Forbidden'}));
  await assertFails(updateDoc(doc(dbFor('alice'),'users/alice'),{role:'admin'}));
  await assertFails(setDoc(doc(dbFor('new'),'users/new'),{name:'New',role:'admin'}));
});
test('server admin claims permit management', async () => {
  const db = dbFor('manager',{admin:true});
  await assertSucceeds(setDoc(doc(db,'products/x'),{name:'Part'}));
  await assertSucceeds(getDocs(collection(db,'maintenance_orders')));
  await assertSucceeds(updateDoc(doc(db,'maintenance_orders/alice-order'),{status:'تم التنفيذ'}));
});
test('order creation validates ownership and initial status', async () => {
  const ref = doc(dbFor('alice'),'scrap_orders/new');
  await assertSucceeds(setDoc(ref,order()));
  await assertFails(setDoc(doc(dbFor('alice'),'scrap_orders/forged'),{...order(),userId:'bob'}));
  await assertFails(setDoc(doc(dbFor('alice'),'scrap_orders/forged-status'),{...order(),status:'تم التنفيذ'}));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(),'scrap_orders/guest'),order()));
});
test('deletion freezes new orders and permits only own data cleanup', async () => {
  const db = dbFor('alice');
  await assertSucceeds(updateDoc(doc(db,'users/alice'),{deletionRequestedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'scrap_orders/after-freeze'),order()));
  await assertSucceeds(deleteDoc(doc(db,'maintenance_orders/alice-order')));
  await assertFails(deleteDoc(doc(db,'maintenance_orders/bob-order')));
  await assertSucceeds(deleteDoc(doc(db,'users/alice')));
});

const pipeOrder = () => ({...order(), serviceType:'تأسيس مواسير التكييفات', address:'القاهرة، شارع الاختبار، الدور الثاني', unitCount:3, description:'قبل التشطيب', imageBase64:null, locationUrl:null});

test('pipe installation lifecycle: create, owner history, admin management, deletion', async () => {
  const db = dbFor('alice');
  const path = 'pipe_installation_orders/new';
  await assertSucceeds(setDoc(doc(db,path),pipeOrder()));
  await assertSucceeds(getDocs(query(collection(db,'pipe_installation_orders'),where('userId','==','alice'))));
  await assertFails(getDocs(collection(db,'pipe_installation_orders')));
  await assertFails(getDoc(doc(dbFor('bob'),path)));
  await assertFails(deleteDoc(doc(dbFor('bob'),path)));
  await assertFails(updateDoc(doc(db,path),{status:'تم التنفيذ'}));
  const admin = dbFor('manager',{admin:true});
  await assertSucceeds(getDocs(collection(admin,'pipe_installation_orders')));
  for (const status of ['قيد المعاينة','تم التنفيذ','ملغي']) {
    await assertSucceeds(updateDoc(doc(admin,path),{status}));
  }
  await assertFails(updateDoc(doc(admin,path),{status:'unknown'}));
  await assertFails(updateDoc(doc(admin,path),{unitCount:99}));
  await assertSucceeds(updateDoc(doc(db,'users/alice'),{deletionRequestedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'pipe_installation_orders/frozen'),pipeOrder()));
  await assertSucceeds(deleteDoc(doc(db,path)));
});

test('pipe installation rejects incomplete, forged and anonymous requests', async () => {
  const db = dbFor('alice');
  for (const patch of [
    {address:''}, {address:'x'.repeat(501)}, {address:5},
    {unitCount:0}, {unitCount:101}, {unitCount:1.5}, {unitCount:'3'},
    {userId:'bob'}, {userEmail:'bob@example.com'}, {status:'تم التنفيذ'},
    {serviceType:'صيانة عامة'}, {unexpected:true},
  ]) {
    await assertFails(setDoc(doc(db,'pipe_installation_orders/invalid'),{...pipeOrder(),...patch}));
  }
  const missing = pipeOrder(); delete missing.address;
  await assertFails(setDoc(doc(db,'pipe_installation_orders/missing'),missing));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(),'pipe_installation_orders/guest'),pipeOrder()));
});
