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

export interface Award {
  id: string;
  name: string;
  icon: string;
  description: string;
}
