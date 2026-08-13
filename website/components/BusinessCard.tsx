import Link from "next/link";
import { BadgeCheck, MapPin, Star } from "lucide-react";
import type { PublicBusiness } from "../lib/api";
const fa = (v: string | number) =>
  new Intl.NumberFormat("fa-IR").format(Number(v));
export function BusinessCard({ b }: { b: PublicBusiness }) {
  return (
    <Link className="business-card" href={`/businesses/${b.slug}`}>
      <div className="business-cover">
        {b.coverUrl ? (
          <img src={b.coverUrl} alt="" />
        ) : (
          <div className="cover-placeholder" />
        )}
        <span className={b.availableNow ? "availability on" : "availability"}>
          {b.availableNow ? "پذیرش دارد" : "در حال حاضر بسته"}
        </span>
      </div>
      <div className="business-card-body">
        <div className="business-title">
          <h3>{b.name}</h3>
          {b.isVerified && (
            <BadgeCheck size={18} aria-label="کسب‌وکار تأییدشده" />
          )}
        </div>
        <div className="meta">
          <Star size={14} />
          <span>{fa(b.averageRating.toFixed(1))}</span>
          <span>({fa(b.reviewsCount)})</span>
        </div>
        <div className="meta">
          <MapPin size={14} />
          <span>{b.city ?? "ایران"}</span>
          <span>·</span>
          <span>{b.businessType.nameFa}</span>
        </div>
      </div>
    </Link>
  );
}
