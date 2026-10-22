import {emptyState,shiftDate,dateKey} from '../src/model.mjs';
// Fictional data only. Relative dates keep a fresh installation useful.
export function demoState(timeZone='UTC') {
  const s=emptyState(timeZone),now=new Date(), day=dateKey(now,timeZone);
  const at=(offset,h)=>new Date(shiftDate(day,offset)+`T${String(h).padStart(2,'0')}:00:00Z`).toISOString();
  s.tasks=[
    {id:'demo:design:brief',course:'Design Studio',title:'Finish the community space brief',kind:'assignment',dueAt:at(1,21),done:false,notes:'Compare two layouts and explain the trade-offs.'},
    {id:'demo:stats:practice',course:'Statistics',title:'Practice set · probability models',kind:'assignment',dueAt:at(2,21),done:false,notes:'Work through questions 1–6. Check your reasoning.'},
    {id:'demo:ecology:notes',course:'Ecology',title:'Prepare field observation notes',kind:'study',dueAt:at(3,21),done:false,notes:'Bring your notebook and review the observation checklist.'},
    {id:'demo:personal:library',course:'Personal',title:'Return library books',kind:'reminder',dueAt:at(4,17),done:false},
    {id:'demo:design:reading',course:'Design Studio',title:'Read the project brief',kind:'study',dueAt:at(0,10),done:true}
  ];
  s.blocks=[{id:'studio',title:'Design Studio · workshop',course:'Design Studio',kind:'course',startAt:at(0,13),endAt:at(0,14),location:'Studio 2'},
    {id:'focus',title:'Work on the community space brief',course:'Design Studio',kind:'work',taskId:s.tasks[0].id,startAt:at(0,15),endAt:at(0,16),location:'Library'},
    {id:'tomorrow',title:'Statistics · tutorial',course:'Statistics',kind:'course',startAt:at(1,14),endAt:at(1,15),location:'Room 204'}];
  s.courses=[{id:'statistics',name:'Statistics',marks:[{id:'a1',title:'Assignment 1',score:92},{id:'a2',title:'Assignment 2',score:108},{id:'a3',title:'Assignment 3',score:null},{id:'m1',title:'Midterm 1',score:78},{id:'m2',title:'Midterm 2',score:null},{id:'exam',title:'Final exam',score:null}],schemes:[
    {name:'Standard scheme',components:[{weight:30,itemIds:['a1','a2','a3'],aggregation:'mean',totalItems:6},{weight:20,itemIds:['m1'],aggregation:'single'},{weight:20,itemIds:['m2'],aggregation:'single'},{weight:30,itemIds:['exam'],aggregation:'single'}]},
    {name:'Alternative scheme',components:[{weight:30,itemIds:['a1','a2','a3'],aggregation:'mean',totalItems:6},{weight:30,itemIds:['m1','m2'],aggregation:'best'},{weight:40,itemIds:['exam'],aggregation:'single'}]}
  ]}];
  s.sources=[{id:'demo',label:'Fictional sample courses',status:'demo',checkedAt:null,note:'Demo records, not a Brightspace review.'}];
  return s;
}
