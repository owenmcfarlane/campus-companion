import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {randomBytes,scryptSync,timingSafeEqual,createHash} from 'node:crypto';
import {readConfig,dataDir} from './config.mjs';
import {openStore} from './store.mjs';
import {widgetPlan} from './widget.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
export function createApp(config,store){
  const secure=new URL(config.origin).protocol==='https:', limits=new Map();
  const hash=v=>createHash('sha256').update(v).digest('hex');
  const headers={'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer','Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"};
  return createServer(async(req,res)=>{
    const send=(code,value,extra={})=>{res.writeHead(code,{...headers,'Content-Type':'application/json',...extra});res.end(JSON.stringify(value));};
    try{
      const url=new URL(req.url,config.origin), path=url.pathname;
      const body=async()=>{let raw='';for await(const b of req){raw+=b;if(Buffer.byteLength(raw)>1_000_000)throw Error('Payload too large');}return JSON.parse(raw);};
      if(!['GET','HEAD'].includes(req.method)&&req.headers.origin!==config.origin) return send(403,{error:'Origin mismatch. Check CAMPUS_ORIGIN and your URL.'});
      const rawCookie=String(req.headers.cookie||'').split(';').map(x=>x.trim()).find(x=>x.startsWith('campus_session='))?.slice(15);
      const session=rawCookie&&store.db.prepare('SELECT expires FROM sessions WHERE id=?').get(hash(rawCookie));
      const signedIn=session&&session.expires>Date.now();
      if(path==='/api/login'&&req.method==='POST'){
        const ip=req.socket.remoteAddress, previous=limits.get(ip),attempt=previous&&previous.until>Date.now()?previous:{count:0,until:Date.now()+600000};
        if(++attempt.count>10)return send(429,{error:'Too many attempts; try again in ten minutes.'});
        limits.set(ip,attempt);if(limits.size>1000)for(const [k,v]of limits)if(v.until<Date.now())limits.delete(k);
        const input=await body();
        if(typeof input.key!=='string'||input.key.length>200) return send(400,{error:'Invalid key'});
        if(!timingSafeEqual(scryptSync(input.key,config.salt,64),Buffer.from(config.passwordHash,'hex')))return send(401,{error:'Incorrect login key'});
        const token=randomBytes(32).toString('base64url');
        store.db.prepare('DELETE FROM sessions WHERE expires<?').run(Date.now());
        store.db.prepare('INSERT INTO sessions VALUES (?,?)').run(hash(token),Date.now()+30*86400000);
        limits.delete(ip);return send(200,{ok:true},{'Set-Cookie':`campus_session=${token}; HttpOnly; SameSite=Strict; Path=/; Max-Age=2592000${secure?'; Secure':''}`});
      }
      if(path.startsWith('/api/')){
        if(!signedIn)return send(401,{error:'Sign in to your private planner'});
        if(path==='/api/logout'&&req.method==='POST'){store.db.prepare('DELETE FROM sessions WHERE id=?').run(hash(rawCookie));return send(200,{ok:true},{'Set-Cookie':'campus_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0'});}
        if(path==='/api/state'&&req.method==='GET')return send(200,{state:store.read(),instanceId:config.instanceId});
        if(path==='/api/operations'&&req.method==='POST'){const result=store.operate(await body());return send(result.conflict?409:200,result);}
        if(path==='/api/widget-plan'&&req.method==='GET')return send(200,widgetPlan(store.read(),config.origin));
        return send(404,{error:'Unknown endpoint'});
      }
      if(req.method!=='GET'&&req.method!=='HEAD')return send(405,{error:'Method not allowed'});
      const files={'/':'web/index.html','/app.js':'web/app.js','/style.css':'web/style.css','/model.mjs':'src/model.mjs','/manifest.webmanifest':'web/manifest.webmanifest','/sw.js':'web/sw.js','/icon.svg':'web/icon.svg','/icon-192.png':'web/icon-192.png','/icon-512.png':'web/icon-512.png','/apple-touch-icon.png':'web/apple-touch-icon.png'};
      if(!files[path])return send(404,{error:'Not found'});
      const content=await readFile(resolve(root,files[path])),ext=path.split('.').pop();
      const type=({'js':'text/javascript','mjs':'text/javascript','css':'text/css','svg':'image/svg+xml','png':'image/png','webmanifest':'application/manifest+json'})[ext]||'text/html';
      res.writeHead(200,{...headers,'Content-Type':type});res.end(req.method==='HEAD'?undefined:content);
    }catch(e){send(400,{error:e.message?.includes('sqlite')?'Storage error':e.message||'Invalid request'});}
  });
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
  const config=readConfig(), store=openStore(resolve(dataDir,'planner.sqlite'));
  const app=createApp(config,store);
  app.listen(config.port,config.host,()=>console.log(`Campus Companion · ${config.origin}`));
  const close=()=>app.close(()=>{store.close();process.exit(0);});process.on('SIGINT',close);process.on('SIGTERM',close);
}
