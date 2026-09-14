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
const change=(current,next)=>admin('/v1/admin/password',{method:'POST',body:{current,next}});
assert.equal((await handleRequest(change(adminToken,oldPassword),env)).status,200);
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
const oldLogin=handleRequest(new Request('https://worker.example/v1/admin/session',{
 method:'POST',body:JSON.stringify({password:oldPassword}),
}),env);
await reached;
const rotated=await handleRequest(change(oldPassword,newPassword),env);
assert.equal(rotated.status,200);
release();
const staleLogin=await oldLogin;
const staleBody=await staleLogin.json();
const authenticated=await handleRequest(admin('/v1/admin/content',{token:staleBody.token}),env);
console.log({passwordChangeStatus:rotated.status,oldPasswordLoginStatus:staleLogin.status,oldPasswordSessionStatus:authenticated.status});
assert.equal(staleLogin.status,200,'Defect: stale verifier permitted a session after password rotation');
assert.equal(authenticated.status,200,'Defect: newly issued old-password session survives rotation');
