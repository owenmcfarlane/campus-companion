// Shared by the browser, server and tests. No model/API calls.
export const VERSION = '1.0.0';
export const dateKey = (date = new Date(), timeZone = 'UTC') => new Intl.DateTimeFormat('en-CA', {timeZone, year:'numeric',month:'2-digit',day:'2-digit'}).format(date);
export function shiftDate(day, n) { const d = new Date(day+'T12:00:00Z'); d.setUTCDate(d.getUTCDate()+n); return d.toISOString().slice(0,10); }
export function emptyState(timeZone = 'UTC') {
  return {schemaVersion:1, revision:0, timeZone, tasks:[], blocks:[], courses:[], sources:[], updatedAt:null};
}
export function priorities(state, now = Date.now()) {
  return state.tasks.filter(t=>!t.done && (!t.availableAt || Date.parse(t.availableAt)<=now))
    .sort((a,b)=>(Date.parse(a.dueAt)||Infinity)-(Date.parse(b.dueAt)||Infinity) || (b.importance??0)-(a.importance??0) || a.id.localeCompare(b.id)).slice(0,3);
}
export function gradeSummary(course, scheme = course.schemes?.[0]) {
  const rows=[];
  for(const component of scheme?.components??[]) {
    const marks=(component.itemIds??[]).map(id=>course.marks.find(m=>m.id===id))
      .filter(m=>m && typeof m.score==='number' && Number.isFinite(m.score) && m.score>=0);
    const selected=component.aggregation==='best'?marks.sort((a,b)=>b.score-a.score).slice(0,1):marks;
    const weight=component.aggregation==='mean'?component.weight/component.totalItems:component.weight;
    for(const mark of selected) rows.push({title:mark.title, score:mark.score, weight, points:mark.score*weight/100});
  }
  const weight=rows.reduce((s,r)=>s+r.weight,0), points=rows.reduce((s,r)=>s+r.points,0);
  return {rows,weight,points,average:weight?points/weight*100:null};
}
const text=(v,max=400)=>typeof v==='string' && v.length>0 && v.length<=max && !/[\u0000-\u001f]/.test(v);
const instant=v=>v===null || (typeof v==='string' && /T.*(?:Z|[+-]\d\d:\d\d)$/.test(v) && Number.isFinite(Date.parse(v)));
const unique=rows=>Array.isArray(rows)&&new Set(rows.map(r=>r.id)).size===rows.length;
export function validateState(s) {
  if(!s || s.schemaVersion!==1 || !Number.isInteger(s.revision) || s.revision<0) throw Error('Invalid state version');
  try {dateKey(new Date(),s.timeZone);} catch {throw Error('Invalid IANA timezone');}
  if(!text(s.timeZone,80)) throw Error('Timezone required');
  if(!unique(s.tasks)||s.tasks.length>3000) throw Error('Task IDs must be unique; maximum 3000');
  for(const t of s.tasks) {
    if(!text(t.id,300)||!text(t.title)||!text(t.course,120)||typeof t.done!=='boolean'||!instant(t.dueAt)||!instant(t.availableAt??null)||!text(t.kind,40)) throw Error('Invalid task');
    if(t.notes!=null && (typeof t.notes!=='string'||t.notes.length>4000)) throw Error('Invalid task notes');
    if(t.sourceUrl && !/^https:\/\//.test(t.sourceUrl)) throw Error('Source links must use HTTPS');
  }
  if(!unique(s.blocks)||s.blocks.length>1000) throw Error('Invalid schedule');
  for(const b of s.blocks) {
    if(!text(b.id,300)||!text(b.title)||!instant(b.startAt)||!b.startAt||!instant(b.endAt)||!b.endAt||Date.parse(b.endAt)<=Date.parse(b.startAt)||dateKey(new Date(b.startAt),s.timeZone)!==dateKey(new Date(Date.parse(b.endAt)-1),s.timeZone)) throw Error('Blocks need valid start/end times within one day');
    if(b.taskId && !s.tasks.some(t=>t.id===b.taskId)) throw Error('Schedule references an unknown task');
  }
  if(!unique(s.courses)||s.courses.length>100) throw Error('Invalid courses');
  for(const c of s.courses) {
    if(!text(c.id,120)||!text(c.name,120)||!unique(c.marks)||!Array.isArray(c.schemes)) throw Error('Invalid grade course');
    for(const m of c.marks) if(!text(m.id,300)||!text(m.title)||!(m.score===null||(Number.isFinite(m.score)&&m.score>=0))) throw Error('Unknown marks must be null');
    for(const scheme of c.schemes) {
      if(!text(scheme.name,120)||!Array.isArray(scheme.components)) throw Error('Invalid grading scheme');
      const ids=[];
      for(const p of scheme.components) {
        if(!Number.isFinite(p.weight)||p.weight<=0||p.weight>100||!Array.isArray(p.itemIds)||!p.itemIds.length||p.itemIds.some(id=>!c.marks.some(m=>m.id===id))) throw Error('Invalid component weight or mark ID');
        if(!['single','mean','best'].includes(p.aggregation)||p.aggregation==='single'&&p.itemIds.length!==1) throw Error('Invalid aggregation');
        if(p.aggregation==='mean'&&(!Number.isInteger(p.totalItems)||p.totalItems<p.itemIds.length||p.totalItems<=0)) throw Error('Equal-weight groups need a confirmed total');
        ids.push(...p.itemIds);
      }
      if(new Set(ids).size!==ids.length||scheme.components.reduce((n,p)=>n+p.weight,0)>100.000001) throw Error('Duplicate or excessive scheme weights');
    }
  }
  if(!Array.isArray(s.sources)||s.sources.length>500) throw Error('Invalid source ledger');
  for(const source of s.sources) if(!text(source.id,300)||!text(source.label)||!['verified','partial','blocked','demo'].includes(source.status)||!instant(source.checkedAt??null)) throw Error('Invalid source receipt');
  return s;
}
export function applyOperation(state, op) {
  const next=structuredClone(state);
  switch(op.type) {
    case 'complete': {
      const t=next.tasks.find(t=>t.id===op.taskId);
      if(!t||typeof op.done!=='boolean') throw Error('Unknown task or invalid completion');
      t.done=op.done; break;
    }
    case 'reminder':
      if(next.tasks.some(t=>t.id===op.task.id)) throw Error('Duplicate reminder');
      next.tasks.push({...op.task,kind:'reminder',done:false}); break;
    case 'block': {
      const i=next.blocks.findIndex(b=>b.id===op.block.id);
      if(i<0) next.blocks.push(op.block); else next.blocks[i]=op.block; break;
    }
    case 'removeBlock': next.blocks=next.blocks.filter(b=>b.id!==op.blockId); break;
    default: throw Error('Unknown operation');
  }
  next.revision++; next.updatedAt=new Date().toISOString(); return validateState(next);
}
export function mergeSourcePacket(state, packet) {
  if(packet.schemaVersion!==1||!Array.isArray(packet.tasks)||!Array.isArray(packet.sources)) throw Error('Invalid import packet');
  const next=structuredClone(state);
  const existing=new Map(next.tasks.map(t=>[t.id,t]));
  if(new Set(packet.tasks.map(t=>t.id)).size!==packet.tasks.length) throw Error('Duplicate imported ID');
  for(const row of packet.tasks) {
    const old=existing.get(row.id);
    // Completion, personal notes and accepted schedule remain student-owned.
    existing.set(row.id,{...old,...row,done:old?.done??false,notes:old?.notes??''});
  }
  next.tasks=[...existing.values()];
  for(const key of ['sources','courses']) if(packet[key]) {
    const map=new Map(next[key].map(r=>[r.id,r]));
    for(const row of packet[key]) {
      const old=map.get(row.id);
      // A failed observation cannot advance the last successful review.
      map.set(row.id,key==='sources'&&row.status!=='verified'?{...row,checkedAt:old?.checkedAt??null}:row);
    }
    next[key]=[...map.values()];
  }
  next.revision++;next.updatedAt=new Date().toISOString();return validateState(next);
}
