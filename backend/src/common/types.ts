import { AccountType } from '@prisma/client';
export type AuthPrincipal = { sub: string; phone: string; accountType: AccountType };
export type PageInfo = { nextCursor: string | null; hasNextPage: boolean };
export type CursorPage<T> = { items: T[]; pageInfo: PageInfo };
