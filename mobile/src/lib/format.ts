export const faNumber=(value:number|bigint|string)=>new Intl.NumberFormat('fa-IR').format(typeof value==='string'?Number(value):value);
export const rial=(value:number|bigint|string)=>`${faNumber(value)} ریال`;
export const jalaliDate=(value:string|Date)=>new Intl.DateTimeFormat('fa-IR-u-ca-persian',{year:'numeric',month:'long',day:'numeric'}).format(new Date(value));
export const jalaliDateTime=(value:string|Date)=>new Intl.DateTimeFormat('fa-IR-u-ca-persian',{dateStyle:'medium',timeStyle:'short'}).format(new Date(value));
export const normalizeDigits=(v:string)=>v.replace(/[۰-۹]/g,d=>String('۰۱۲۳۴۵۶۷۸۹'.indexOf(d))).replace(/[٠-٩]/g,d=>String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)));
