// Offline regression check. Fake WebSocket; no browser or network access.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const {PassThrough} = require('node:stream');
const assert = require('node:assert/strict');
const input = new PassThrough();
const records = [];
let socketCount = 0, lastSocket, wake = () => {};
const attachments = new Map();
const activated = [];
const targets = [
  {type:'page',targetId:'resume',url:'https://example.test/resume'},
  {type:'page',targetId:'jobs',url:'https://example.test/jobs'}
];
class FakeSocket {
  constructor() {
    socketCount++;
    lastSocket = this;
    this.readyState = 0;
    queueMicrotask(() => { this.readyState = 1; this.onopen(); });
  }
  send(raw) {
    const {id, method, params, sessionId} = JSON.parse(raw);
    let result;
    if (method === 'Browser.getVersion') result = {product:'Edg/mock'};
    else if (method === 'Target.getTargets') result = {targetInfos:targets};
    else if (method === 'Target.attachToTarget') {
      attachments.set(params.targetId, (attachments.get(params.targetId) || 0) + 1);
      result = {sessionId:params.targetId};
    } else if (method === 'Target.activateTarget') {
      activated.push(params.targetId);
      result = {};
    } else if (method === 'Runtime.evaluate') {
      result = {result:{value:JSON.stringify({url:targets.find(t=>t.targetId===sessionId).url,text:'Mock page'})}};
    } else throw new Error('Unexpected CDP method: '+method);
    queueMicrotask(() => this.onmessage({data:JSON.stringify({id,result})}));
  }
  close() {
    this.readyState = 3;
    queueMicrotask(() => this.onclose());
  }
}
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'cdp-inspect.cjs'),'utf8'), {
  require, URL, WebSocket:FakeSocket, setTimeout, clearTimeout,
  process:{argv:['node','cdp-inspect.cjs'],env:{},stdin:input,exit:()=>{throw new Error('Unexpected exit');}},
  console:{log:line=>{records.push(JSON.parse(line));wake();},error:line=>{throw new Error(line);}}
});
function until(predicate) {
  if (predicate()) return Promise.resolve();
  return new Promise((resolve,reject)=>{
    const timer = setTimeout(()=>reject(new Error('Offline check timed out')),2000);
    wake = () => {if(predicate()){clearTimeout(timer);resolve();}};
  });
}
function send(id,url,extra={}) { input.write(JSON.stringify({id,action:'inspect',url,...extra})+'\n'); }
(async()=>{
  assert.equal(socketCount,0,'starting the process must not connect');
  send(1,targets[0].url);
  send(2,targets[1].url);
  send(3,targets[0].url,{foreground:true});
  await until(()=>records.some(r=>r.id===3));
  for (const id of [1,2,3]) assert.equal(records.find(r=>r.id===id).ok,true);
  assert.equal(socketCount,1,'different pages must reuse one browser connection');
  assert.equal(attachments.get('resume'),1,'returning to a page must reuse its attachment');
  assert.equal(attachments.get('jobs'),1);
  assert.deepEqual(activated,['resume'],'foreground must activate only the requested existing target');
  targets[1].url = 'https://login.example.test/signin?token=private#secret';
  input.write(JSON.stringify({id:'redirect-list',action:'list'})+'\n');
  await until(()=>records.some(r=>r.id==='redirect-list'));
  const listed=records.find(r=>r.id==='redirect-list');
  assert.equal(listed.ok,true);
  assert.equal(listed.page[1].url,'https://login.example.test/signin');
  assert.equal(socketCount,1,'listing redirected pages must reuse the connection');
  assert.equal(attachments.get('jobs'),1,'listing must not attach pages again');
  lastSocket.close();
  await until(()=>records.some(r=>r.event==='disconnected'));
  send(4,targets[0].url);
  await until(()=>records.some(r=>r.id===4));
  assert.equal(records.find(r=>r.id===4).ok,false);
  assert.equal(socketCount,1,'disconnect must not cause automatic reconnection');
  input.end();
  console.log('PASS: lazy connection; one connection across pages; page attachments reused; foreground on the same socket; no automatic reconnection. Offline only.');
})().catch(error=>{console.error(error);process.exitCode=1;input.end();});
