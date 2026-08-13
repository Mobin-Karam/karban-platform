import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Badge, ConfirmButton, PageHeader } from '../components/ui';
import { DataTable, type Column } from '../components/DataTable';
import { PaginationBar } from '../components/PaginationBar';
import { useDebouncedValue } from '../hooks/useDebouncedValue';
import { api, patch } from '../lib/api';
import { date, rial } from '../lib/format';

type Invoice = { id:string; invoiceNo:string; status:string; totalRial:string; paidRial:string; issuedAt:string|null; business:{name:string}; customer:{phone:string;profile:{displayName:string}|null}; _count:{items:number;renders:number} };
type Page = { items:Invoice[]; pageInfo:{hasNextPage:boolean;nextCursor:string|null} };
const statusFa:Record<string,string>={DRAFT:'پیش‌نویس',ISSUED:'صادرشده',PARTIALLY_PAID:'نیمه‌پرداخت',PAID:'پرداخت‌شده',VOID:'باطل',CANCELLED:'لغوشده'};
export function InvoicesAdminPage(){
  const [q,setQ]=useState('');const [status,setStatus]=useState('');const [cursor,setCursor]=useState<string|undefined>();const dq=useDebouncedValue(q);const qc=useQueryClient();
  const data=useQuery({queryKey:['admin-invoices',dq,status,cursor],queryFn:()=>api<Page>(`/admin/invoices?q=${encodeURIComponent(dq)}&status=${encodeURIComponent(status)}${cursor?`&cursor=${cursor}`:''}`)});
  const cols:Column<Invoice>[]=[
    {key:'no',title:'صورتحساب',render:r=><div className="cell-main"><b className="mono">{r.invoiceNo}</b><span>{r.business.name}</span></div>},
    {key:'customer',title:'مشتری',render:r=><div className="cell-main"><b>{r.customer.profile?.displayName??'بدون نام'}</b><span dir="ltr">{r.customer.phone}</span></div>},
    {key:'amount',title:'مبلغ',render:r=><div className="cell-main"><b>{rial(r.totalRial)}</b><span>پرداخت: {rial(r.paidRial)}</span></div>},
    {key:'status',title:'وضعیت',render:r=><Badge tone={r.status==='PAID'?'good':r.status==='VOID'||r.status==='CANCELLED'?'bad':'info'}>{statusFa[r.status]??r.status}</Badge>},
    {key:'date',title:'صدور',render:r=>r.issuedAt?date(r.issuedAt):'—'},
    {key:'count',title:'اقلام/فایل',render:r=>`${r._count.items} / ${r._count.renders}`},
    {key:'actions',title:'عملیات',render:r=>r.status==='VOID'||r.status==='CANCELLED'||r.status==='PAID'?<span>—</span>:<div className="row-actions"><ConfirmButton variant="secondary" title="باطل کردن صورتحساب" description="مبالغ و سوابق حذف نمی‌شوند؛ فقط وضعیت مالی صورتحساب باطل می‌شود." onConfirm={async()=>{await patch(`/admin/invoices/${r.id}/status`,{status:'VOID'});await qc.invalidateQueries({queryKey:['admin-invoices']})}}>باطل</ConfirmButton><ConfirmButton title="لغو صورتحساب" description="لغو صورتحساب برگشت‌پذیر خودکار نیست و در Audit Log ثبت می‌شود." onConfirm={async()=>{await patch(`/admin/invoices/${r.id}/status`,{status:'CANCELLED'});await qc.invalidateQueries({queryKey:['admin-invoices']})}}>لغو</ConfirmButton></div>},
  ];
  return <><PageHeader title="صورتحساب‌ها" subtitle="ثبت مالی پس از صدور و پرداخت دستکاری نمی‌شود؛ مدیر فقط کنترل وضعیت و بررسی را انجام می‌دهد." actions={<><select className="page-search" value={status} onChange={e=>{setStatus(e.target.value);setCursor(undefined)}}><option value="">همه وضعیت‌ها</option>{Object.entries(statusFa).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select><input className="page-search" value={q} onChange={e=>{setQ(e.target.value);setCursor(undefined)}} placeholder="شماره یا نام کسب‌وکار"/></>}/><DataTable rows={data.data?.items??[]} columns={cols}/><PaginationBar canNext={Boolean(data.data?.pageInfo.hasNextPage)} onNext={()=>{const n=data.data?.pageInfo.nextCursor;if(n)setCursor(n)}} onReset={()=>setCursor(undefined)}/></>;
}
