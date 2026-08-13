import { Button } from './ui';
export function PaginationBar({canNext,onNext,onReset}:{canNext:boolean;onNext:()=>void;onReset:()=>void}){return <div className="pagination-bar"><Button variant="secondary" onClick={onReset}>ابتدای فهرست</Button><Button disabled={!canNext} onClick={onNext}>صفحه بعد</Button></div>}
