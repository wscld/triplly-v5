import { PublicProfile, PublicTravelDetail } from "./types";

const API_BASE = "https://app.triplly.com/api";

export async function getPublicProfile(
  username: string
): Promise<PublicProfile | null> {
  try {
    const res = await fetch(`${API_BASE}/public/users/${username}`, {
      next: { revalidate: 60 },
    });

    if (!res.ok) return null;

    return res.json();
  } catch {
    return null;
  }
}

export async function getPublicTravelDetail(
  travelId: string
): Promise<PublicTravelDetail | null> {
  try {
    const res = await fetch(`${API_BASE}/public/travels/${travelId}`, {
      next: { revalidate: 60 },
    });

    if (!res.ok) return null;

    return res.json();
  } catch {
    return null;
  }
}
