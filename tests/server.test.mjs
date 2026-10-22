import test from 'node:test';import assert from 'node:assert/strict';import {scryptSync} from 'node:crypto';
import {createApp} from '../src/server.mjs';import {openStore} from '../src/store.mjs';
test('authentication, CSRF, private APIs and logout',async()=>{
 const store=openStore(':memory:'),salt='f'.repeat(32),config={origin:'http://localhost',salt,passwordHash:scryptSync('test-only-key',salt,64).toString('hex'),instanceId:'test-instance'};
 const app=createApp(config,store);await new Promise(r=>app.listen(0,'127.0.0.1',r));const url=`http://127.0.0.1:${app.address().port}`;
 try{
  assert.equal((await fetch(url+'/api/state')).status,401);
  assert.equal((await fetch(url+'/api/login',{method:'POST',body:'{}'})).status,403);
  const login=await fetch(url+'/api/login',{method:'POST',headers:{origin:config.origin},body:JSON.stringify({key:'test-only-key'})});assert.equal(login.status,200);
  const cookie=login.headers.get('set-cookie').split(';')[0],headers={cookie,origin:config.origin};
  const data=await fetch(url+'/api/state',{headers});assert.equal(data.status,200);assert.equal(data.headers.get('cache-control'),'no-store');
  assert.equal((await fetch(url+'/api/operations',{method:'POST',headers:{cookie,origin:'https://evil.example'},body:'{}'})).status,403);
  assert.equal((await fetch(url+'/.local/login-key.txt',{headers})).status,404);
  assert.equal((await fetch(url+'/api/logout',{method:'POST',headers,body:'{}'})).status,200);
  assert.equal((await fetch(url+'/api/state',{headers})).status,401);
 }finally{await new Promise(r=>app.close(r));store.close();}
});
