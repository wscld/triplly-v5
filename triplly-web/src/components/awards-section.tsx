import { Award } from "@/lib/types";
import { getAwardIcon } from "@/lib/awards-icons";

interface AwardsSectionProps {
  awards: Award[];
}

const colorMap: Record<string, { bg: string; text: string }> = {
  emerald: { bg: "bg-emerald-100", text: "text-emerald-600" },
  teal: { bg: "bg-teal-100", text: "text-teal-600" },
  cyan: { bg: "bg-cyan-100", text: "text-cyan-600" },
  blue: { bg: "bg-blue-100", text: "text-blue-600" },
  indigo: { bg: "bg-indigo-100", text: "text-indigo-600" },
  violet: { bg: "bg-violet-100", text: "text-violet-600" },
  purple: { bg: "bg-purple-100", text: "text-purple-600" },
  pink: { bg: "bg-pink-100", text: "text-pink-600" },
  rose: { bg: "bg-rose-100", text: "text-rose-600" },
  amber: { bg: "bg-amber-100", text: "text-amber-600" },
  orange: { bg: "bg-orange-100", text: "text-orange-600" },
  yellow: { bg: "bg-yellow-100", text: "text-yellow-600" },
  slate: { bg: "bg-slate-100", text: "text-slate-600" },
};

function getColorClasses(color: string) {
  return colorMap[color] ?? colorMap.emerald;
}

export function AwardsSection({ awards }: AwardsSectionProps) {
  if (awards.length === 0) return null;

  return (
    <div className="space-y-3">
      <h2 className="px-1 text-sm font-semibold uppercase tracking-wide text-gray-500">
        Awards
      </h2>
      <div className="flex gap-4 overflow-x-auto pb-2">
        {awards.map((award) => {
          const Icon = getAwardIcon(award.icon);
          const colors = getColorClasses(award.color);
          return (
            <div
              key={award.id}
              className="flex flex-col items-center gap-1.5"
              title={award.description}
            >
              <div className={`flex h-11 w-11 items-center justify-center rounded-full shadow-sm ${colors.bg}`}>
                <Icon className={`h-5 w-5 ${colors.text}`} />
              </div>
              <span className="w-16 text-center text-[10px] font-medium leading-tight text-gray-500">
                {award.name}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
