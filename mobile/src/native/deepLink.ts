export async function installPaymentDeepLinkHandler(onResult:(result:{status:string;purpose:string;attemptId:string})=>void){
  if(!('__TAURI_INTERNALS__' in window))return()=>{};
  const{getCurrent,onOpenUrl}=await import('@tauri-apps/plugin-deep-link');
  const handle=(urls:string[])=>{for(const raw of urls){try{const u=new URL(raw);if(u.protocol!=='karban:'||u.hostname!=='payment')continue;onResult({status:u.searchParams.get('status')??'UNKNOWN',purpose:u.searchParams.get('purpose')??'OTHER',attemptId:u.searchParams.get('attemptId')??''})}catch{/* ignore malformed external links */}}};
  const current=await getCurrent();if(current)handle(current);const unlisten=await onOpenUrl(handle);return unlisten;
}
