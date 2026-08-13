export const API =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3000/api/v1";
export type PublicBusiness = {
  id: string;
  slug: string;
  name: string;
  description: string | null;
  logoUrl: string | null;
  coverUrl: string | null;
  city: string | null;
  province: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  isVerified: boolean;
  averageRating: number;
  reviewsCount: number;
  availableNow: boolean;
  businessType: { key: string; nameFa: string };
  owner: { profile: { displayName: string } | null };
  services?: {
    id: string;
    name: string;
    description: string | null;
    priceRial: string | null;
    durationMinutes: number | null;
  }[];
  reviews?: {
    id: string;
    rating: number;
    body: string | null;
    createdAt: string;
    customer: { profile: { displayName: string } | null };
  }[];
};
export async function directory(
  params = "",
): Promise<{
  items: PublicBusiness[];
  pageInfo: { nextCursor: string | null; hasNextPage: boolean };
}> {
  try {
    const r = await fetch(`${API}/businesses/discover?limit=18&${params}`, {
      next: { revalidate: 60 },
    });
    if (!r.ok)
      return { items: [], pageInfo: { nextCursor: null, hasNextPage: false } };
    const j = (await r.json()) as {
      data?: {
        items: PublicBusiness[];
        pageInfo: { nextCursor: string | null; hasNextPage: boolean };
      };
    };
    return (
      j.data ?? {
        items: [],
        pageInfo: { nextCursor: null, hasNextPage: false },
      }
    );
  } catch {
    return { items: [], pageInfo: { nextCursor: null, hasNextPage: false } };
  }
}
export async function business(slug: string): Promise<PublicBusiness | null> {
  try {
    const r = await fetch(
      `${API}/businesses/public/${encodeURIComponent(slug)}`,
      { next: { revalidate: 60 } },
    );
    if (!r.ok) return null;
    const j = (await r.json()) as { data?: PublicBusiness };
    return j.data ?? null;
  } catch {
    return null;
  }
}
