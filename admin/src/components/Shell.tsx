import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useEffect, useRef } from 'react';
import { Icon, type IconName } from './Icon';

const nav:Array<{to:string;label:string;icon:IconName;key:string}>=[
  {to:'/',label:'داشبورد',icon:'dashboard',key:'d'},
  {to:'/users',label:'کاربران',icon:'users',key:'u'},
  {to:'/businesses',label:'کسب‌وکارها',icon:'businesses',key:'b'},
  {to:'/business-types',label:'نوع کسب‌وکار',icon:'package',key:'t'},
  {to:'/invoices',label:'صورتحساب‌ها',icon:'invoices',key:'n'},
  {to:'/payments',label:'پرداخت‌ها',icon:'money',key:'y'},
  {to:'/reviews',label:'نظرات',icon:'reports',key:'e'},
  {to:'/inventory',label:'انبار',icon:'inventory',key:'k'},
  {to:'/wallets',label:'کیف پول',icon:'wallet',key:'w'},
  {to:'/features',label:'قابلیت‌ها',icon:'features',key:'f'},
  {to:'/sms',label:'پیامک',icon:'sms',key:'m'},
  {to:'/verification',label:'احراز هویت',icon:'verification',key:'v'},
  {to:'/staff',label:'پرسنل',icon:'staff',key:'s'},
  {to:'/plans',label:'پلن و باشگاه',icon:'plans',key:'p'},
  {to:'/reports',label:'گزارش‌ها',icon:'reports',key:'r'},
  {to:'/integrations',label:'اتصال سرویس‌ها',icon:'integrations',key:'i'},
  {to:'/audit',label:'Audit Log',icon:'logs',key:'l'},
];
export function Shell(){
  const go=useNavigate();const pending=useRef<string|null>(null);
  useEffect(()=>{const h=(e:KeyboardEvent)=>{const target=e.target as HTMLElement;if(['INPUT','TEXTAREA','SELECT'].includes(target.tagName))return;if(e.key.toLowerCase()==='g'){pending.current='g';setTimeout(()=>pending.current=null,800);return}if(pending.current==='g'){const item=nav.find(n=>n.key===e.key.toLowerCase());if(item){e.preventDefault();go(item.to);pending.current=null}}};window.addEventListener('keydown',h);return()=>window.removeEventListener('keydown',h)},[go]);
  return <div className="admin-shell"><aside><div className="admin-brand"><img src="/brand/logo.svg" alt=""/><div><b>کاربان</b><span>کنترل سیستم</span></div></div><nav>{nav.map(n=><NavLink key={n.to} to={n.to} end={n.to==='/'}><Icon name={n.icon}/><span>{n.label}</span><kbd>G {n.key.toUpperCase()}</kbd></NavLink>)}</nav><div className="aside-footer">نسخه ۰.۱.۰</div></aside><main><div className="topbar"><div className="top-search"><Icon name="search"/><input id="global-search" placeholder="جستجوی سریع"/></div><div className="top-actions"><button aria-label="اعلان‌ها"><Icon name="bell"/></button></div></div><div className="content"><Outlet/></div></main></div>;
}
