import Image from "next/image";
import Link from "next/link";
import { PublicTravel } from "@/lib/types";
import { Calendar } from "lucide-react";

interface TravelCardProps {
  travel: PublicTravel;
  username: string;
}

function formatDateRange(start: string | null, end: string | null): string | null {
  if (!start) return null;
  const fmt = (d: string) =>
    new Date(d).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  if (!end) return fmt(start);
  return `${fmt(start)} — ${fmt(end)}`;
}

export function TravelCard({ travel, username }: TravelCardProps) {
  const dateStr = formatDateRange(travel.startDate, travel.endDate);

  return (
    <Link
      href={`/u/${username}/travel/${travel.id}`}
      className="block overflow-hidden rounded-2xl bg-white shadow-sm ring-1 ring-gray-100 transition-shadow hover:shadow-md"
    >
      {travel.coverImageUrl && (
        <div className="relative h-44 w-full">
          <Image
            src={travel.coverImageUrl}
            alt={travel.title}
            fill
            className="object-cover"
          />
        </div>
      )}
      <div className="space-y-1.5 p-4">
        <h3 className="text-base font-semibold text-gray-900">
          {travel.title}
        </h3>
        {travel.description && (
          <p className="text-sm text-gray-500 line-clamp-2">
            {travel.description}
          </p>
        )}
        {dateStr && (
          <div className="flex items-center gap-1.5 text-xs text-gray-400">
            <Calendar className="h-3.5 w-3.5" />
            <span>{dateStr}</span>
          </div>
        )}
      </div>
    </Link>
  );
}
