import Image from "next/image";
import { Award } from "@/lib/types";
import { getAwardIcon, getBadgeImagePath } from "@/lib/awards-icons";

interface AwardsSectionProps {
  awards: Award[];
}

export function AwardsSection({ awards }: AwardsSectionProps) {
  if (awards.length === 0) return null;

  return (
    <div className="space-y-3">
      <h2 className="px-1 text-sm font-semibold uppercase tracking-wide text-gray-500">
        Awards
      </h2>
      <div className="flex overflow-x-auto pb-2">
        <div className="flex items-center">
          {awards.map((award, index) => {
            const badgePath = getBadgeImagePath(award.id);
            const Icon = getAwardIcon(award.icon);
            return (
              <div
                key={award.id}
                className="relative"
                style={{ marginLeft: index === 0 ? 0 : -20, zIndex: awards.length - index }}
                title={award.description}
              >
                {badgePath ? (
                  <Image
                    src={badgePath}
                    alt={award.name}
                    width={56}
                    height={56}
                    className="h-14 w-14 object-contain drop-shadow-md"
                  />
                ) : (
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100 ring-2 ring-white shadow-sm">
                    <Icon className="h-5 w-5 text-emerald-600" />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
