import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
export const dataDir=resolve(process.env.CAMPUS_DATA_DIR||'.local');
export function readConfig(){
  let c;try{c=JSON.parse(readFileSync(resolve(dataDir,'config.json'),'utf8'));}catch{throw Error('Run npm run setup first. See START-HERE.md.');}
  const url=new URL(c.origin);
  if(!['http:','https:'].includes(url.protocol)||url.pathname!=='/'||url.search||url.hash||url.username||url.password)throw Error('Origin must be a bare HTTP(S) origin');
  if(url.protocol!=='https:'&&!['localhost','127.0.0.1','[::1]'].includes(url.hostname))throw Error('Remote access requires HTTPS');
  if(!/^[a-f0-9]{128}$/.test(c.passwordHash)||!/^[a-f0-9]{32}$/.test(c.salt))throw Error('Invalid authentication configuration');
  return c;
}
