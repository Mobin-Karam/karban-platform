import { spawnSync } from 'node:child_process';
const steps=[
  ['config','node',['scripts/check-config.mjs']],
  ['source syntax','node',['scripts/audit-source.mjs']],
  ['relative imports','node',['scripts/check-local-imports.mjs']],
  ['assets','node',['scripts/check-assets.mjs']],
  ['docker yaml','python3',['-c',`import yaml,pathlib; d=yaml.safe_load(pathlib.Path('docker-compose.yml').read_text()); assert set(d['services'])=={'postgres','backend'}; assert 'redis' not in d['services']; print('docker yaml audit: services='+','.join(sorted(d['services'])))`]],
  ['mobile token persistence','bash',['-lc',`if grep -R -nE "localStorage\.(getItem|setItem).*accessToken|sessionStorage\.(getItem|setItem).*accessToken" mobile/src; then echo 'persisted bearer token found'; exit 1; else echo 'mobile token persistence audit: clean'; fi`]],
];
let failed=0;
for(const [name,cmd,args] of steps){console.log(`\n== ${name} ==`);const r=spawnSync(cmd,args,{stdio:'inherit'});if(r.status!==0){failed++;console.error(`FAILED: ${name}`)}}
console.log(`\naudit summary: ${steps.length-failed}/${steps.length} checks passed`);process.exit(failed?1:0);
