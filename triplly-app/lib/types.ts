export interface User {
    id: string;
    email: string;
    name: string;
    profilePhotoUrl?: string | null;
    createdAt: string;
}

export interface Travel {
    id: string;
    title: string;
    description: string | null;
    startDate: string | null;
    endDate: string | null;
    coverImageUrl: string | null;
    ownerId: string;
    owner: { id: string; name: string; email?: string };
    createdAt: string;
    itineraries?: Itinerary[];
}

export interface TravelListItem extends Travel {
    role: 'owner' | 'editor' | 'viewer';
}

export interface TravelMember {
    id: string;
    userId: string;
    role: 'owner' | 'editor' | 'viewer';
    joinedAt: string;
    user: { id: string; name: string; email: string; profilePhotoUrl?: string | null };
}

export interface Itinerary {
    id: string;
    travelId: string;
    title: string;
    date: string | null;
    orderIndex: number;
    activities?: Activity[];
}

export interface Activity {
    id: string;
    travelId: string;
    itineraryId: string | null;
    title: string;
    description: string | null;
    orderIndex: number;
    latitude: number;
    longitude: number;
    googlePlaceId: string | null;
    createdAt: string;
    startTime?: string | null;
    comments?: ActivityComment[];
    address?: string | null;
    createdById?: string | null;
    createdBy?: { id: string; name: string; email: string } | null;
}

export interface ActivityComment {
    id: string;
    activityId: string;
    userId: string;
    content: string;
    createdAt: string;
    user: { id: string; name: string; email: string };
}

export interface CreateTravelData {
    title: string;
    description?: string | null;
    startDate?: string | null;
    endDate?: string | null;
}

export interface CreateItineraryData {
    travelId: string;
    title: string;
    date?: string | null;
}

export interface CreateActivityData {
    travelId: string;
    itineraryId?: string | null; // null = wishlist
    title: string;
    description?: string | null;
    latitude: number;
    longitude: number;
    googlePlaceId?: string | null;
    startTime?: string | null;
    address?: string | null;
}

export interface UpdateActivityData {
    title?: string;
    description?: string | null;
    latitude?: number;
    longitude?: number;
    googlePlaceId?: string | null;
    startTime?: string | null;
}

export interface ReorderActivityData {
    activityId: string;
    afterActivityId: string | null;
    beforeActivityId: string | null;
}

export interface Todo {
    id: string;
    travelId: string;
    title: string;
    isCompleted: boolean;
    createdAt: string;
    updatedAt: string;
}

export interface CreateTodoData {
    travelId: string;
    title: string;
}

export interface UpdateTodoData {
    title?: string;
    isCompleted?: boolean;
}

export interface AuthResponse {
    user: User;
    token: string;
}
