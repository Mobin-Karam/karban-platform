import type { ComponentType } from "react";
import {
  Bell,
  Building2,
  ChevronLeft,
  CircleDollarSign,
  Download,
  FileText,
  Home,
  Image,
  MapPin,
  Menu,
  MessageSquareMore,
  Package,
  Search,
  Settings,
  ShieldCheck,
  Star,
  Store,
  UserRound,
  UsersRound,
  WalletCards,
  Wrench,
  Plus,
  ArrowRight,
  Check,
  Clock3,
  Phone,
  Send,
  Boxes,
  ReceiptText,
  CreditCard,
  Coins,
  LogOut,
  RefreshCw,
  Flag,
} from "lucide-react";
const registry = {
  home: Home,
  search: Search,
  business: Building2,
  store: Store,
  invoice: FileText,
  receipt: ReceiptText,
  wallet: WalletCards,
  coins: Coins,
  inventory: Boxes,
  package: Package,
  review: Star,
  verified: ShieldCheck,
  location: MapPin,
  user: UserRound,
  users: UsersRound,
  settings: Settings,
  bell: Bell,
  message: MessageSquareMore,
  wrench: Wrench,
  plus: Plus,
  back: ArrowRight,
  chevron: ChevronLeft,
  check: Check,
  clock: Clock3,
  phone: Phone,
  send: Send,
  download: Download,
  image: Image,
  card: CreditCard,
  logout: LogOut,
  refresh: RefreshCw,
  menu: Menu,
  money: CircleDollarSign,
  flag: Flag,
} as const;
export type IconName = keyof typeof registry;
export function Icon({
  name,
  size = 20,
  className,
}: {
  name: IconName;
  size?: number;
  className?: string;
}) {
  const C = registry[name] as ComponentType<{
    size?: number;
    className?: string;
    strokeWidth?: number;
  }>;
  return <C size={size} className={className} strokeWidth={1.8} />;
}
