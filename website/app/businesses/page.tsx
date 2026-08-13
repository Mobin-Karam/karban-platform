import { directory } from "../../lib/api";
import { BusinessCard } from "../../components/BusinessCard";
export const metadata = {
  title: "کسب‌وکارها",
  description:
    "جست‌وجو و مشاهده کسب‌وکارهای خدماتی و لوله‌کش‌های فعال در کاربان.",
};
export default async function Businesses({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; city?: string; verified?: string }>;
}) {
  const p = await searchParams;
  const qs = new URLSearchParams();
  if (p.q) qs.set("q", p.q);
  if (p.city) qs.set("city", p.city);
  if (p.verified) qs.set("verifiedOnly", p.verified);
  const d = await directory(qs.toString());

  
  return (
    <section className="directory section">
      <div className="section-head">
        <span>دایرکتوری خدمات</span>
        <h1>لوله‌کش و کسب‌وکار خدماتی را پیدا کنید</h1>
      </div>
      <form className="directory-filter">
        <input name="q" defaultValue={p.q} placeholder="نام یا خدمت" />
        <input name="city" defaultValue={p.city} placeholder="شهر" />
        <label>
          <input
            type="checkbox"
            name="verified"
            value="true"
            defaultChecked={p.verified === "true"}
          />{" "}
          فقط تأییدشده
        </label>
        <button>جست‌وجو</button>
      </form>
      <div className="business-grid">
        {d.items.map((b) => (
          <BusinessCard key={b.id} b={b} />
        ))}
      </div>
      {d.items.length === 0 && (
        <div className="empty">
          موردی پیدا نشد. بعد از اتصال API و ایجاد کسب‌وکارها، نتایج اینجا نمایش
          داده می‌شوند.
        </div>
      )}
    </section>
  );
}
