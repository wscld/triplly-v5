import { Metadata } from "next";
import { notFound } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { getPublicTravelDetail } from "@/lib/api";
import { PublicActivity } from "@/lib/types";
import { OpenInAppBanner } from "@/components/open-in-app-banner";
import { Calendar, MapPin, Clock, ArrowLeft } from "lucide-react";

interface Props {
  params: Promise<{ username: string; travelId: string }>;
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

function formatItineraryDate(date: string | null): string | null {
  if (!date) return null;
  return new Date(date).toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
}

function formatTime(time: string | null): string | null {
  if (!time) return null;
  const [hours, minutes] = time.split(":");
  const h = parseInt(hours, 10);
  const ampm = h >= 12 ? "PM" : "AM";
  const h12 = h % 12 || 12;
  return `${h12}:${minutes} ${ampm}`;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { travelId } = await params;
  const travel = await getPublicTravelDetail(travelId);

  if (!travel) {
    return { title: "Travel not found — Triplly" };
  }

  const title = `${travel.title} — Triplly`;
  const description = travel.description || `Check out this travel on Triplly`;

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "article",
      images: travel.coverImageUrl ? [travel.coverImageUrl] : [],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: travel.coverImageUrl ? [travel.coverImageUrl] : [],
    },
  };
}

function ActivityRow({ activity }: { activity: PublicActivity }) {
  return (
    <div className="flex gap-3 rounded-xl bg-white p-3 shadow-sm ring-1 ring-gray-100">
      <div className="flex-1 space-y-1">
        <p className="text-sm font-medium text-gray-900">{activity.title}</p>
        {activity.description && (
          <p className="text-xs text-gray-500 line-clamp-2">
            {activity.description}
          </p>
        )}
        <div className="flex flex-wrap gap-3">
          {activity.startTime && (
            <span className="flex items-center gap-1 text-xs text-gray-400">
              <Clock className="h-3 w-3" />
              {formatTime(activity.startTime)}
            </span>
          )}
          {activity.address && (
            <span className="flex items-center gap-1 text-xs text-gray-400">
              <MapPin className="h-3 w-3" />
              <span className="line-clamp-1">{activity.address}</span>
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

export default async function TravelDetailPage({ params }: Props) {
  const { username, travelId } = await params;
  const travel = await getPublicTravelDetail(travelId);

  if (!travel) notFound();

  const dateStr = formatDateRange(travel.startDate, travel.endDate);

  return (
    <div className="min-h-screen bg-gray-50">
      <OpenInAppBanner username={username} />

      <main className="mx-auto max-w-lg pb-12">
        {/* Cover image */}
        {travel.coverImageUrl && (
          <div className="relative h-52 w-full">
            <Image
              src={travel.coverImageUrl}
              alt={travel.title}
              fill
              className="object-cover"
            />
          </div>
        )}

        <div className="px-4">
          {/* Back link */}
          <Link
            href={`/u/${username}`}
            className="mt-4 inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            Back to profile
          </Link>

          {/* Header */}
          <div className="mt-3 space-y-2">
            <h1 className="text-2xl font-bold text-gray-900">
              {travel.title}
            </h1>
            {dateStr && (
              <div className="flex items-center gap-1.5 text-sm text-gray-500">
                <Calendar className="h-4 w-4" />
                <span>{dateStr}</span>
              </div>
            )}
            {travel.description && (
              <p className="text-sm text-gray-600">{travel.description}</p>
            )}
          </div>

          {/* Itineraries */}
          {travel.itineraries.length > 0 ? (
            <div className="mt-8 space-y-6">
              {travel.itineraries.map((itinerary) => (
                <section key={itinerary.id}>
                  <div className="mb-3 flex items-baseline gap-2">
                    <h2 className="text-base font-semibold text-gray-900">
                      {itinerary.title}
                    </h2>
                    {itinerary.date && (
                      <span className="text-xs text-gray-400">
                        {formatItineraryDate(itinerary.date)}
                      </span>
                    )}
                  </div>
                  {itinerary.activities.length > 0 ? (
                    <div className="space-y-2">
                      {itinerary.activities.map((activity) => (
                        <ActivityRow key={activity.id} activity={activity} />
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-gray-400">No activities yet</p>
                  )}
                </section>
              ))}
            </div>
          ) : (
            <div className="mt-12 text-center">
              <p className="text-sm text-gray-400">
                No itineraries added yet
              </p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
