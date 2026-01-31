import { Metadata } from "next";
import { notFound } from "next/navigation";
import { getPublicProfile } from "@/lib/api";
import { ProfileHeader } from "@/components/profile-header";
import { AwardsSection } from "@/components/awards-section";
import { TravelCard } from "@/components/travel-card";
import { OpenInAppBanner } from "@/components/open-in-app-banner";

interface Props {
  params: Promise<{ username: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { username } = await params;
  const profile = await getPublicProfile(username);

  if (!profile) {
    return { title: "Profile not found — Triplly" };
  }

  const title = `${profile.name} on Triplly`;
  const description = `Check out ${profile.name}'s travels and awards on Triplly`;

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "profile",
      images: profile.profilePhotoUrl ? [profile.profilePhotoUrl] : [],
    },
    twitter: {
      card: "summary",
      title,
      description,
      images: profile.profilePhotoUrl ? [profile.profilePhotoUrl] : [],
    },
  };
}

export default async function ProfilePage({ params }: Props) {
  const { username } = await params;
  const profile = await getPublicProfile(username);

  if (!profile) notFound();

  return (
    <div className="min-h-screen bg-gray-50">
      <OpenInAppBanner username={profile.username} />

      <main className="mx-auto max-w-lg px-4 pb-12">
        <ProfileHeader
          name={profile.name}
          username={profile.username}
          profilePhotoUrl={profile.profilePhotoUrl}
        />

        {profile.awards.length > 0 && (
          <div className="mb-6">
            <AwardsSection awards={profile.awards} />
          </div>
        )}

        {profile.travels.length > 0 && (
          <div className="space-y-4">
            <h2 className="px-1 text-sm font-semibold uppercase tracking-wide text-gray-500">
              Travels
            </h2>
            {profile.travels.map((travel) => (
              <TravelCard key={travel.id} travel={travel} username={profile.username} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
