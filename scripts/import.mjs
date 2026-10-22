import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {dataDir,readConfig} from '../src/config.mjs';
import {openStore} from '../src/store.mjs';
import {mergeSourcePacket} from '../src/model.mjs';
const file=process.argv[2];if(!file)throw Error('Usage: npm run import -- source-packet.local.json [--apply --revision N]');
readConfig();const store=openStore(resolve(dataDir,'planner.sqlite'));
try{
 const packet=JSON.parse(readFileSync(file,'utf8')),current=store.read(),next=mergeSourcePacket(current,packet);
 console.log(JSON.stringify({currentRevision:current.revision,taskCount:next.tasks.length,changedTaskIds:next.tasks.filter(t=>JSON.stringify(t)!==JSON.stringify(current.tasks.find(o=>o.id===t.id))).map(t=>t.id),sourceStatuses:next.sources.map(s=>({id:s.id,status:s.status,checkedAt:s.checkedAt})),gradeCourses:next.courses.map(c=>c.name)},null,2));
 if(process.argv.includes('--apply')){const at=process.argv.indexOf('--revision');if(at<0)throw Error('An explicit --revision from the preview is required');store.import(packet,Number(process.argv[at+1]));console.log('Imported atomically. Device sync is a separate check.');}
 else console.log(`Preview only. To apply this reviewed packet: npm run import -- "${file}" --apply --revision ${current.revision}`);
}finally{store.close();}
