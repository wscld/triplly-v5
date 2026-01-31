export interface PublicProfile {
  id: string;
  name: string;
  username: string;
  profilePhotoUrl: string | null;
  travels: PublicTravel[];
  awards: Award[];
}

export interface PublicTravel {
  id: string;
  title: string;
  description: string | null;
  startDate: string | null;
  endDate: string | null;
  coverImageUrl: string | null;
  latitude: number | null;
  longitude: number | null;
}

export interface PublicTravelDetail {
  id: string;
  title: string;
  description: string | null;
  startDate: string | null;
  endDate: string | null;
  coverImageUrl: string | null;
  latitude: number | null;
  longitude: number | null;
  owner: {
    id: string;
    name: string;
  };
  itineraries: PublicItinerary[];
}

export interface PublicItinerary {
  id: string;
  title: string;
  date: string | null;
  orderIndex: number;
  activities: PublicActivity[];
}

export interface PublicActivity {
  id: string;
  title: string;
  description: string | null;
  address: string | null;
  startTime: string | null;
  latitude: number;
  longitude: number;
  orderIndex: number;
}

export interface Award {
  id: string;
  name: string;
  icon: string;
  description: string;
}
