import { create } from 'zustand';
import { clearAccessToken, setAccessToken } from '../lib/session';

type User = { id: string; phone: string; accountType: string };
type AuthState = {
  user: User | null;
  setSession: (token: string, user: User) => void;
  logout: () => void;
};

/**
 * Authentication is intentionally not rehydrated from ordinary WebView storage.
 * Persisting login across native restarts belongs behind SecureStorageProvider.
 */
export const useAuth = create<AuthState>((set) => ({
  user: null,
  setSession: (token, user) => {
    setAccessToken(token);
    set({ user });
  },
  logout: () => {
    clearAccessToken();
    set({ user: null });
  },
}));
