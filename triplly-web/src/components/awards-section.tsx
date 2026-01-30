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
      <div className="flex gap-3 overflow-x-auto pb-2">
        {awards.map((award) => {
          const badgePath = getBadgeImagePath(award.id);
          const Icon = getAwardIcon(award.icon);
          return (
            <div
              key={award.id}
              className="flex min-w-[80px] flex-col items-center gap-1.5 rounded-xl bg-gray-50 p-3"
              title={award.description}
            >
              {badgePath ? (
                <Image
                  src={badgePath}
                  alt={award.name}
                  width={56}
                  height={56}
                  className="h-14 w-14 object-contain"
                />
              ) : (
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-100">
                  <Icon className="h-5 w-5 text-emerald-600" />
                </div>
              )}
              <span className="text-center text-xs font-medium text-gray-700">
                {award.name}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
