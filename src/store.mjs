import {DatabaseSync} from 'node:sqlite';
import {mkdirSync} from 'node:fs';
import {dirname} from 'node:path';
import {applyOperation, emptyState, mergeSourcePacket, validateState} from './model.mjs';
export function openStore(path, initial=emptyState()) {
  if(path!==':memory:') mkdirSync(dirname(path),{recursive:true,mode:0o700});
  const db=new DatabaseSync(path);
  db.exec('PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000; CREATE TABLE IF NOT EXISTS state (id INTEGER PRIMARY KEY, body TEXT); CREATE TABLE IF NOT EXISTS receipts (id TEXT PRIMARY KEY, body TEXT); CREATE TABLE IF NOT EXISTS history (revision INTEGER PRIMARY KEY, body TEXT); CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, expires INTEGER);');
  db.prepare('INSERT OR IGNORE INTO state VALUES (1,?)').run(JSON.stringify(validateState(initial)));
  const read=()=>JSON.parse(db.prepare('SELECT body FROM state WHERE id=1').get().body);
  function save(next) {
    const old=read();
    db.prepare('INSERT OR IGNORE INTO history VALUES (?,?)').run(old.revision,JSON.stringify(old));
    db.prepare('UPDATE state SET body=? WHERE id=1').run(JSON.stringify(next));
  }
  function transact(fn) {db.exec('BEGIN IMMEDIATE');try {const r=fn();db.exec('COMMIT');return r;}catch(e){db.exec('ROLLBACK');throw e;}}
  return {db,read,close:()=>db.close(),
    operate(op) {return transact(()=>{
      if(typeof op.id!=='string'||! /^[a-zA-Z0-9-]{8,100}$/.test(op.id))throw Error('Invalid operation ID');
      const previous=db.prepare('SELECT body FROM receipts WHERE id=?').get(op.id);
      if(previous) {
        if(previous.body!==JSON.stringify(op))throw Error('Operation ID already used for different content');
        return {state:read(),duplicate:true};
      }
      const state=read();
      if(op.expectedRevision!==state.revision) return {conflict:true,state};
      const next=applyOperation(state,op);save(next);
      db.prepare('INSERT INTO receipts VALUES (?,?)').run(op.id,JSON.stringify(op));
      return {state:next};
    });},
    import(packet,expectedRevision) {return transact(()=>{const old=read();if(old.revision!==expectedRevision)throw Error('State changed; inspect again before importing');const next=mergeSourcePacket(old,packet);save(next);return next;});}
  };
}
