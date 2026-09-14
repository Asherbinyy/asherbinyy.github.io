// Sanitized, local-only reproduction. No network or repository mutation.
import assert from 'node:assert/strict';
import {webcrypto} from 'node:crypto';
import {pathToFileURL} from 'node:url';
globalThis.crypto ??= webcrypto;
const checkout=process.argv[2];
if (!checkout) throw new Error('Pass the absolute cb13007 admin checkout path');
const local=p=>pathToFileURL(`${checkout}/${p}`).href;
const {handleRequest}=await import(local('worker/src/index.js'));
const {ContentStore}=await import(local('worker/src/store.js'));
const {durableNamespace}=await import(local('worker/dev/durable-double.js'));
const {admin,adminToken,environment}=await import(local('worker/test/support.js'));
const env=environment({CONTENT_STORE:durableNamespace(ContentStore)});
const oldPassword='fixture-old-password-123';
const newPassword='fixture-new-password-456';
const overwrittenPassword='fixture-overwrite-password-789';
const change=(current,next)=>admin('/v1/admin/password',{method:'POST',body:{current,next}});
const seeded=await handleRequest(change(adminToken,oldPassword),env);
assert.equal(seeded.status,200);
const {token:oldSession}=await seeded.json();
const ns=env.CONTENT_STORE, originalGet=ns.get.bind(ns);
let entered, release;
const reached=new Promise(resolve=>entered=resolve);
const gate=new Promise(resolve=>release=resolve);
let first=true;
ns.get=(...args)=>{
 const stub=originalGet(...args);
 return {fetch:async(url,init)=>{
  const asked=JSON.parse(init.body);
  const response=await stub.fetch(url,init);
  if(first&&asked.op==='password'&&asked.action==='get'){
   first=false; entered(); await gate;
  }
  return response;
 }};
};
const staleRotation=handleRequest(admin('/v1/admin/password',{
 method:'POST',token:oldSession,body:{current:oldPassword,next:overwrittenPassword},
}),env);
await reached;
const rotated=await handleRequest(change(adminToken,newPassword),env);
assert.equal(rotated.status,200);
release();
const staleResponse=await staleRotation;
const staleBody=await staleResponse.json();
const signIn=password=>handleRequest(new Request('https://worker.example/v1/admin/session',{
 method:'POST',body:JSON.stringify({password}),
}),env);
const ownerLogin=await signIn(newPassword);
const staleActorLogin=await signIn(overwrittenPassword);
const staleSession=await handleRequest(admin('/v1/admin/content',{token:oldSession}),env);
console.log({ownerRotation:rotated.status,staleRotation:staleResponse.status,ownerNewPassword:ownerLogin.status,staleActorPassword:staleActorLogin.status,oldSession:staleSession.status});
assert.equal(staleResponse.status,401);
assert.equal(staleBody.reason,'password-rotated');
assert.equal(staleBody.token,undefined);
assert.equal(ownerLogin.status,200);
assert.equal(staleActorLogin.status,401);
assert.equal(staleSession.status,401);
