// Keep one Edge CDP connection for a whole task. Send JSON commands on stdin.
const readline = require('node:readline');
const fs = require('node:fs');
const path = require('node:path');
if (process.argv.includes('--help')) {
  console.log('Start once: node scripts/cdp-inspect.cjs');
  console.log('Then send JSON lines on the same stdin:');
  console.log('{"action":"inspect","url":"https://join.qq.com/","open":false}');
  console.log('{"action":"quit"}');
  console.log('Connections and page attachments are reused. No automatic reconnection.');
  process.exit(0);
}
if (process.argv.length > 2) {
  console.error('Single-use mode removed. Run with --help for persistent-session usage.');
  process.exit(1);
}

let socket, connectPromise, seq = 0, quitting = false;
const pending = new Map(), pageSessions = new Map();
const output = value => console.log(JSON.stringify(value));
function call(method, params = {}, sessionId, timeout = 15000) {
  if (socket?.readyState !== 1) return Promise.reject(new Error('CDP is not connected'));
  return new Promise((resolve, reject) => {
    const id = ++seq;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`CDP request timed out: ${method}; no reconnection attempted`));
    }, timeout);
    pending.set(id, {resolve, reject, timer});
    try {
      socket.send(JSON.stringify({id, method, params, ...(sessionId ? {sessionId} : {})}));
    } catch (error) {
      clearTimeout(timer); pending.delete(id); reject(error);
    }
  });
}
async function connect() {
  const endpoint = process.env.EDGE_CDP_URL || 'ws://localhost:9222/devtools/browser';
  const parsed = new URL(endpoint);
  if (parsed.protocol !== 'ws:' || !['localhost', '127.0.0.1', '[::1]'].includes(parsed.hostname)) {
    throw new Error('Expected a local ws:// Edge CDP endpoint');
  }
  socket = new WebSocket(endpoint);
  socket.onmessage = e => {
    const message = JSON.parse(e.data);
    if (message.method === 'Target.detachedFromTarget') {
      for (const [targetId, sessionId] of pageSessions) {
        if (sessionId === message.params.sessionId) pageSessions.delete(targetId);
      }
    }
    const p = pending.get(message.id);
    if (!p) return;
    pending.delete(message.id); clearTimeout(p.timer);
    message.error ? p.reject(new Error(message.error.message)) : p.resolve(message.result);
  };
  socket.onclose = () => {
    pageSessions.clear();
    for (const p of pending.values()) {
      clearTimeout(p.timer); p.reject(new Error('CDP connection closed; no automatic reconnection'));
    }
    pending.clear();
    if (!quitting) output({event:'disconnected', reconnect:false});
  };
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.close(); reject(new Error('CDP connection timed out; no automatic reconnection'));
    }, 60000);
    socket.onopen = () => { clearTimeout(timer); resolve(); };
    socket.onerror = () => { clearTimeout(timer); reject(new Error('CDP connection failed; no automatic reconnection')); };
  });
  const version = await call('Browser.getVersion');
  if (!version.product.startsWith('Edg/')) {
    socket.close(); throw new Error('Connected browser is not Edge; stopped');
  }
  output({event:'connected', browser:version.product});
}
async function inspect(command) {
  const targetUrl = new URL(command.url);
  if (targetUrl.protocol !== 'https:') throw new Error('Expected an https:// page URL');
  // A failed connection remains failed. Never prompt repeatedly by reconnecting.
  if (!connectPromise) connectPromise = connect();
  await connectPromise;
  const {targetInfos} = await call('Target.getTargets');
  let matches = targetInfos.filter(t => t.type === 'page' && t.url.startsWith(targetUrl.href));
  if (!matches.length && command.open === true) {
    const {targetId} = await call('Target.createTarget', {url:targetUrl.href});
    matches = [{targetId}];
  }
  if (matches.length !== 1) throw new Error(`Expected one matching page; found ${matches.length}`);
  const targetId = matches[0].targetId;
  let sessionId = pageSessions.get(targetId);
  if (!sessionId) {
    ({sessionId} = await call('Target.attachToTarget', {targetId, flatten:true}));
    pageSessions.set(targetId, sessionId);
  }
  // Some sites gate React rendering behind animations in hidden tabs.
  // Activate the existing target over this socket, never open another client.
  if (command.foreground === true) await call('Target.activateTarget', {targetId});
  const defaultExpression = `JSON.stringify({url:location.href,title:document.title,readyState:document.readyState,text:(document.body?.innerText||'').slice(0,18000),links:Array.from(document.querySelectorAll('a[href]')).slice(0,60).map(a=>({text:a.innerText.slice(0,160),url:a.href})),editors:Array.from(document.querySelectorAll('.cm-content,.ace_text-layer,textarea')).map(e=>({type:e.className,text:(e.value||e.innerText||'').slice(0,18000)})),frames:Array.from(document.querySelectorAll('iframe')).map(f=>({title:f.title,src:f.src}))})`;
  const expression = command.action === 'evaluate' ? fs.readFileSync(workspacePath(command.expressionFile), 'utf8') : defaultExpression;
  const result = await call('Runtime.evaluate', {expression, returnByValue:true, awaitPromise:true, userGesture:true}, sessionId, Math.min(60000, Math.max(15000,command.timeout || 15000)));
  if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text || 'DOM inspection failed');
  if (command.action === 'evaluate') {
    if (command.saveResultTo) {
      const destination = workspacePath(command.saveResultTo);
      const value = result.result.value;
      if (typeof value !== 'string') throw new Error('Saving requires a string result');
      const buffer = Buffer.from(value,command.encoding === 'base64' ? 'base64' : 'utf8');
      fs.mkdirSync(path.dirname(destination), {recursive:true});
      fs.writeFileSync(destination, buffer);
      return {savedTo:destination, bytes:buffer.length};
    }
    return result.result.value;
  }
  return JSON.parse(result.result.value);
}

async function listPages() {
  if (!connectPromise) connectPromise = connect();
  await connectPromise;
  const {targetInfos} = await call('Target.getTargets');
  // Paths identify redirects; omit query strings and fragments which may contain tokens.
  return targetInfos.filter(t => t.type === 'page').map(t => {
    let url;
    try { const u = new URL(t.url); url = u.origin + u.pathname; }
    catch { url = 'unavailable'; }
    return {targetId:t.targetId, url};
  });
}

function workspacePath(value) {
  if (typeof value !== 'string') throw new Error('Expected workspace file path');
  const root = path.resolve(process.cwd());
  const resolved = path.resolve(root,value);
  const relative = path.relative(root,resolved);
  if (relative === '..' || relative.startsWith('..'+path.sep) || path.isAbsolute(relative)) throw new Error('File must stay inside the current workspace');
  return resolved;
}

const input = readline.createInterface({input:process.stdin, terminal:false});
let queue = Promise.resolve();
input.on('line', line => {
  if (!line.trim()) return;
  queue = queue.then(async () => {
    let command;
    try {
      command = JSON.parse(line);
      if (command.action === 'quit') {
        quitting = true; input.close(); socket?.close();
        output({ok:true, action:'quit'}); return;
      }
      if (quitting) throw new Error('Session already stopped');
      if (!['inspect','evaluate','list'].includes(command.action)) throw new Error('Supported actions: inspect, evaluate, list, quit');
      output({ok:true, id:command.id, page:command.action === 'list' ? await listPages() : await inspect(command)});
    } catch (error) {
      output({ok:false, id:command?.id, error:error.message});
    }
  });
});
input.on('close', () => {
  queue.then(() => { quitting = true; socket?.close(); });
});
output({event:'ready', connected:false, mode:'persistent'});

