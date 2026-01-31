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

/** Award IDs that have custom badge images in /public/badges/ */
const badgeImages: Set<string> = new Set([
  "first-steps",
  "solo-adventurer",
]);

/**
 * Returns the path to a custom badge image for the given award ID,
 * or null if no custom image exists (falls back to icon).
 */
export function getBadgeImagePath(awardId: string): string | null {
  const slug = awardId.replaceAll("_", "-");
  return badgeImages.has(slug) ? `/badges/${slug}.png` : null;
}
