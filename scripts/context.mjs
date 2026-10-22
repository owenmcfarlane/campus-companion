import {resolve} from 'node:path';
import {readConfig,dataDir} from '../src/config.mjs';
import {openStore} from '../src/store.mjs';
readConfig();const store=openStore(resolve(dataDir,'planner.sqlite'));
try{const s=store.read(),id=process.argv[2];console.log(JSON.stringify(id?s.tasks.filter(t=>t.id===id):{revision:s.revision,timeZone:s.timeZone,open:s.tasks.filter(t=>!t.done).length,total:s.tasks.length,sources:s.sources,grades:s.courses.map(c=>({id:c.id,name:c.name,recorded:c.marks.filter(m=>m.score!==null).length})),tasks:s.tasks.map(t=>({id:t.id,title:t.title,dueAt:t.dueAt,done:t.done}))},null,id?2:0));}finally{store.close();}
