import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import { Button, Card, PageHeader, Screen, Skeleton } from "../components/ui";

import { Icon } from "../design/Icon";
import { api, post } from "../lib/api";
import { useAuth } from "../stores/auth";
import { faNumber, rial } from "../lib/format";

type ReviewUser = {
  profile?: {
    displayName?: string | null;
  } | null;
} | null;

type Review = {
  id: string;
  rating: number;
  body: string | null;
  ownerReply: string | null;

  /*
   * The backend may return null/undefined when:
   * - the user was deleted
   * - relation wasn't included
   * - profile doesn't exist
   */
  user?: ReviewUser;
};

type Service = {
  id: string;
  name: string;
  description: string | null;
  priceRial: string | number;
  unitLabel: string;
};

type ServiceCategory = {
  id: string;
  name: string;
  services?: Service[] | null;
};

type Detail = {
  id: string;
  name: string;

  bio: string | null;
  phone: string | null;
  address: string | null;
  city: string | null;

  coverUrl: string | null;
  logoUrl: string | null;

  isAvailable: boolean;
  isVerified: boolean;

  averageRating: number | null;
  reviewsCount: number;

  serviceCategories?: ServiceCategory[] | null;
  reviews?: Review[] | null;
};

function getReviewerName(review: Review): string {
  const name = review.user?.profile?.displayName?.trim();

  return name || "مشتری";
}

function SafeImage({
  src,
  className,
  alt = "",
}: {
  src: string;
  className?: string;
  alt?: string;
}) {
  const [failed, setFailed] = useState(false);

  if (!src || failed) {
    return null;
  }

  return (
    <img
      src={src}
      className={className}
      alt={alt}
      loading="lazy"
      onError={() => setFailed(true)}
    />
  );
}

export function BusinessDetailPage() {
  const { slug } = useParams<{ slug: string }>();

  const nav = useNavigate();

  const q = useQuery({
    queryKey: ["business", slug],

    queryFn: async () => {
      if (!slug) {
        throw new Error("Business slug is missing");
      }

      return api<Detail>(`/businesses/public/${encodeURIComponent(slug)}`);
    },

    enabled: Boolean(slug),

    retry: 1,
  });

  /*
   * Loading
   */
  if (q.isLoading) {
    return (
      <Screen>
        <Skeleton className="detail-cover" />
        <Skeleton className="line wide" />
        <Skeleton className="line" />
      </Screen>
    );
  }

  /*
   * API error
   */
  if (q.isError) {
    return (
      <Screen>
        <PageHeader title="خطا در دریافت اطلاعات" back onBack={() => nav(-1)} />

        <Card>
          <p>دریافت اطلاعات کسب‌وکار با مشکل مواجه شد.</p>

          <Button onClick={() => void q.refetch()}>تلاش مجدد</Button>
        </Card>
      </Screen>
    );
  }

  /*
   * Business not found
   */
  if (!q.data) {
    return (
      <Screen>
        <PageHeader title="کسب‌وکار پیدا نشد" back onBack={() => nav(-1)} />
      </Screen>
    );
  }

  const b = q.data;

  const categories = b.serviceCategories ?? [];
  const reviews = b.reviews ?? [];

  const averageRating =
    typeof b.averageRating === "number" ? b.averageRating : 0;

  return (
    <Screen className="detail-screen">
      {/* ==============================
          Hero
      ============================== */}

      <div className="detail-hero">
        {b.coverUrl ? (
          <SafeImage src={b.coverUrl} alt={b.name} />
        ) : (
          <div className="cover-fallback">
            <Icon name="wrench" size={42} />
          </div>
        )}

        <button
          type="button"
          className="floating-back"
          onClick={() => nav(-1)}
          aria-label="بازگشت"
        >
          <Icon name="back" />
        </button>
      </div>

      <div className="detail-main">
        {/* ==============================
            Business name
        ============================== */}

        <div className="detail-name">
          <div>
            {b.logoUrl ? (
              <SafeImage
                className="detail-logo"
                src={b.logoUrl}
                alt={`${b.name} logo`}
              />
            ) : null}

            <h1>{b.name}</h1>

            {b.isVerified ? (
              <Icon name="verified" className="verified" />
            ) : null}
          </div>

          <span className={`availability ${b.isAvailable ? "on" : "off"}`}>
            {b.isAvailable ? "در دسترس" : "فعلاً غیرفعال"}
          </span>
        </div>

        {/* ==============================
            Rating
        ============================== */}

        <div className="rating-line">
          <Icon name="review" size={17} />

          <b>{faNumber(averageRating.toFixed(1))}</b>

          <span>از {faNumber(b.reviewsCount ?? reviews.length)} نظر</span>
        </div>

        {/* ==============================
            Bio
        ============================== */}

        {b.bio ? <p className="detail-bio">{b.bio}</p> : null}

        {/* ==============================
            Contact actions
        ============================== */}

        <div className="detail-actions">
          <Button
            icon="phone"
            disabled={!b.phone}
            onClick={() => {
              if (!b.phone) return;

              window.location.href = `tel:${b.phone}`;
            }}
          >
            تماس
          </Button>

          <Button variant="secondary" icon="message">
            پیام
          </Button>
        </div>

        {/* ==============================
            Services
        ============================== */}

        <section className="detail-section">
          <h2>خدمات و قیمت‌ها</h2>

          {categories.length === 0 ? (
            <Card>
              <p>هنوز خدمتی برای این کسب‌وکار ثبت نشده است.</p>
            </Card>
          ) : (
            categories.map((category) => {
              const services = category.services ?? [];

              return (
                <div key={category.id} className="service-group">
                  <h3>{category.name}</h3>

                  {services.length === 0 ? (
                    <Card>
                      <p>خدمتی در این دسته وجود ندارد.</p>
                    </Card>
                  ) : (
                    services.map((service) => (
                      <Card key={service.id} className="service-row">
                        <div>
                          <b>{service.name}</b>

                          {service.description ? (
                            <p>{service.description}</p>
                          ) : null}
                        </div>

                        <span>
                          {rial(service.priceRial)} / {service.unitLabel}
                        </span>
                      </Card>
                    ))
                  )}
                </div>
              );
            })
          )}
        </section>

        {/* ==============================
            Reviews
        ============================== */}

        <section className="detail-section">
          <h2>نظر مشتری‌ها</h2>

          <ReviewComposer
            businessId={b.id}
            onDone={() => {
              void q.refetch();
            }}
          />

          {reviews.length === 0 ? (
            <Card>
              <p>هنوز نظری برای این کسب‌وکار ثبت نشده است.</p>
            </Card>
          ) : (
            reviews.map((review) => (
              <Card key={review.id} className="review-card">
                <div className="review-head">
                  <b>{getReviewerName(review)}</b>

                  <span>
                    <Icon name="review" size={14} />

                    {faNumber(review.rating ?? 0)}
                  </span>
                </div>

                {review.body ? <p>{review.body}</p> : null}

                {review.ownerReply ? (
                  <div className="owner-reply">
                    <b>پاسخ کسب‌وکار</b>

                    <p>{review.ownerReply}</p>
                  </div>
                ) : null}
              </Card>
            ))
          )}
        </section>
      </div>
    </Screen>
  );
}

/* ==========================================
   Review Composer
========================================== */

export function ReviewComposer({
  businessId,
  onDone,
}: {
  businessId: string;
  onDone: () => void;
}) {
  const user = useAuth((state) => state.user);

  const [rating, setRating] = useState(5);

  const [body, setBody] = useState("");

  const [submitting, setSubmitting] = useState(false);

  const [error, setError] = useState<string | null>(null);

  /*
   * Only authenticated users can review.
   */
  if (!user) {
    return null;
  }

  async function submitReview() {
    if (submitting) return;

    setSubmitting(true);
    setError(null);

    try {
      await post(`/reviews/business/${businessId}`, {
        rating,
        body: body.trim(),
      });

      setBody("");
      setRating(5);

      onDone();
    } catch (err) {
      console.error("Failed to submit review:", err);

      setError("ثبت نظر انجام نشد. دوباره تلاش کنید.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Card className="review-compose">
      <h3>نظر شما</h3>

      <div className="rating-picker">
        {[1, 2, 3, 4, 5].map((value) => (
          <button
            key={value}
            type="button"
            className={value <= rating ? "on" : ""}
            onClick={() => setRating(value)}
            aria-label={`${value} ستاره`}
          >
            <Icon name="review" />
          </button>
        ))}
      </div>

      <label className="field">
        <span>تجربه شما</span>

        <textarea
          value={body}
          onChange={(event) => setBody(event.target.value)}
          placeholder="نظر خود را بنویسید..."
          rows={4}
        />
      </label>

      {error ? (
        <p className="form-error" role="alert">
          {error}
        </p>
      ) : null}

      <Button disabled={submitting} onClick={() => void submitReview()}>
        {submitting ? "در حال ثبت..." : "ثبت نظر"}
      </Button>
    </Card>
  );
}
