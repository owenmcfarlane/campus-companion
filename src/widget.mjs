import {dateKey,shiftDate} from './model.mjs';
// Find midnight in an IANA zone without assuming a fixed offset or a 24-hour day.
export function midnight(day,zone){
  let lo=Date.parse(day+'T00:00:00Z')-36*3600000, hi=lo+72*3600000;
  while(hi-lo>1){const m=Math.floor((lo+hi)/2);if(dateKey(new Date(m),zone)<day)lo=m;else hi=m;}
  return new Date(hi).toISOString();
}
export function widgetPlan(state,origin,now=new Date()){
  const day=dateKey(now,state.timeZone), end=shiftDate(day,8);
  const events=state.blocks.filter(b=>{
    const d=dateKey(new Date(b.startAt),state.timeZone);
    return d>=day&&d<end&&(d===day||b.kind==='course')&&!state.tasks.find(t=>t.id===b.taskId)?.done;
  }).slice(0,80).map(b=>{
    const d=dateKey(new Date(b.startAt),state.timeZone),q=new URLSearchParams({date:d,block:b.id});if(b.taskId)q.set('task',b.taskId);
    return {id:`${d}|${b.id}`,kind:b.kind==='course'?'course':'work',title:b.title,course:b.course||'',courseKey:'other',startAt:b.startAt,endAt:b.endAt,location:b.location||null,preparation:[],taskId:b.taskId||null,url:`${origin}/?${q}`,nextStep:null};
  });
  return {version:1,generatedAt:now.toISOString(),planDate:day,timeZone:state.timeZone,revision:state.revision,validUntil:midnight(shiftDate(day,1),state.timeZone),events};
}
