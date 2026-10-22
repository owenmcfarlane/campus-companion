import {execFileSync} from 'node:child_process';import {readFileSync,existsSync} from 'node:fs';import {dirname,resolve} from 'node:path';
const files=execFileSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{encoding:'utf8'}).split('\0').filter(Boolean);
let failures=[];
for(const file of files){
 if(/(^|\/)(\.local|node_modules|xcuserdata)\/|\.sqlite|login-key\.txt|source-packet\.local|setup-state\.local/.test(file))failures.push(`${file}: private runtime file`);
 if(/\.(png|jpg|jpeg|ico)$/.test(file))continue;
 const text=readFileSync(file,'utf8');
 const patterns=[/-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----/,/gh[pousr]_[A-Za-z0-9]{30,}/,/\/Users\/[a-z][^\s"']+\//,new RegExp('owen'+'-student-sticky'),new RegExp('dal'+'.brightspace.com'),/DEVELOPMENT_TEAM = [A-Z0-9]{10};/];
 if(patterns.some(p=>p.test(text)))failures.push(`${file}: possible private data or credential`);
 if(/\.(mjs|js)$/.test(file))try{execFileSync(process.execPath,['--check',file],{stdio:'pipe'});}catch{failures.push(`${file}: invalid JavaScript`);}
 if(file.endsWith('.md')){
  for(const match of text.matchAll(/\]\(([^)]+)\)|(?:src|href)="([^"]+)"/g)){
   const link=match[1]||match[2];if(/^(https?:|mailto:|#)/.test(link))continue;
   if(!existsSync(resolve(dirname(file),decodeURI(link.split('#')[0]))))failures.push(`${file}: missing link ${link}`);
  }
 }
}
if(failures.length){console.error(failures.join('\n'));process.exit(1);}
console.log(`Checked ${files.length} publishable files: syntax, local links and private-data guards passed. Manual diff review still required.`);
