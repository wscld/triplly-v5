import {
  Footprints,
  Map,
  Globe,
  Plane,
  User,
  Moon,
  Users,
  Crown,
  ClipboardList,
  Zap,
  MessageCircle,
  Award,
  type LucideIcon,
} from "lucide-react";

const sfSymbolToLucide: Record<string, LucideIcon> = {
  "figure.walk": Footprints,
  map: Map,
  "globe.americas": Globe,
  globe: Globe,
  "airplane.circle": Plane,
  "person.fill": User,
  "moon.stars": Moon,
  "person.3.fill": Users,
  crown: Crown,
  "list.clipboard": ClipboardList,
  "bolt.fill": Zap,
  "text.bubble": MessageCircle,
};

export function getAwardIcon(sfSymbolName: string): LucideIcon {
  return sfSymbolToLucide[sfSymbolName] ?? Award;
}
