import type {
    User,
    Travel,
    TravelListItem,
    TravelMember,
    Itinerary,
    Activity,
    CreateTravelData,
    CreateItineraryData,
    CreateActivityData,
    UpdateActivityData,
    ReorderActivityData,
    AuthResponse,
    ActivityComment,
    Todo,
    CreateTodoData,
    UpdateTodoData,
} from './types';
import { tokenStorage } from './storage';

const API_URL = process.env.EXPO_PUBLIC_API_URL
    ? `${process.env.EXPO_PUBLIC_API_URL}/api`
    : 'http://localhost:3000/api';

class ApiClient {
    private token: string | null = null;

    async init() {
        this.token = await tokenStorage.getItem();
    }

    setToken(token: string | null) {
        this.token = token;
        if (token) {
            tokenStorage.setItem(token);
        } else {
            tokenStorage.removeItem();
        }
    }

    private async request<T>(
        path: string,
        options: RequestInit = {}
    ): Promise<T> {
        const headers: HeadersInit = {
            'Content-Type': 'application/json',
            ...(options.headers || {}),
        };

        if (this.token) {
            (headers as Record<string, string>)['Authorization'] = `Bearer ${this.token}`;
        }

        const response = await fetch(`${API_URL}${path}`, {
            ...options,
            headers,
        });

        if (!response.ok) {
            console.error('API Request Failed:', response.status, response.statusText);
            const error = await response.json().catch(() => ({ error: 'Request failed' }));
            console.error('API Error Body:', error);
            throw new Error(error.error || `Request failed: ${response.status}`);
        }

        return response.json();
    }

    // Auth
    async register(email: string, password: string, name: string): Promise<AuthResponse> {
        const result = await this.request<AuthResponse>('/auth/register', {
            method: 'POST',
            body: JSON.stringify({ email, password, name }),
        });
        this.setToken(result.token);
        return result;
    }

    async login(email: string, password: string): Promise<AuthResponse> {
        const result = await this.request<AuthResponse>('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        });
        this.setToken(result.token);
        return result;
    }

    async logout() {
        this.setToken(null);
    }

    async getMe(): Promise<User> {
        return this.request<User>('/auth/me');
    }

    // Travels
    async getTravels(): Promise<TravelListItem[]> {
        return this.request<TravelListItem[]>('/travels');
    }

    async getTravel(id: string): Promise<Travel> {
        return this.request<Travel>(`/travels/${id}`);
    }

    async createTravel(data: CreateTravelData): Promise<Travel> {
        return this.request<Travel>('/travels', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    async updateTravel(id: string, data: Partial<CreateTravelData>): Promise<Travel> {
        return this.request<Travel>(`/travels/${id}`, {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    async uploadTravelCover(id: string, file: any): Promise<{ coverImageUrl: string }> {
        const formData = new FormData();
        formData.append('file', {
            uri: file.uri,
            name: file.fileName || 'cover.jpg',
            type: file.mimeType || 'image/jpeg',
        } as any);

        const response = await fetch(`${API_URL}/travels/${id}/cover`, {
            method: 'POST',
            body: formData,
            headers: {
                ...(this.token ? { 'Authorization': `Bearer ${this.token}` } : {}),
            },
        });

        if (!response.ok) {
            throw new Error('Upload failed');
        }

        return response.json();
    }

    async deleteTravel(id: string): Promise<void> {
        await this.request(`/travels/${id}`, { method: 'DELETE' });
    }

    // Members
    async getTravelMembers(travelId: string): Promise<TravelMember[]> {
        return this.request<TravelMember[]>(`/travels/${travelId}/members`);
    }

    async inviteMember(travelId: string, email: string, role: 'editor' | 'viewer'): Promise<TravelMember> {
        return this.request<TravelMember>(`/travels/${travelId}/members`, {
            method: 'POST',
            body: JSON.stringify({ email, role }),
        });
    }

    async updateMemberRole(travelId: string, memberId: string, role: 'editor' | 'viewer'): Promise<void> {
        await this.request(`/travels/${travelId}/members/${memberId}`, {
            method: 'PATCH',
            body: JSON.stringify({ role }),
        });
    }

    async removeMember(travelId: string, memberId: string): Promise<void> {
        await this.request(`/travels/${travelId}/members/${memberId}`, { method: 'DELETE' });
    }

    // Itineraries
    async getItinerary(id: string): Promise<Itinerary> {
        return this.request<Itinerary>(`/itineraries/${id}`);
    }

    async createItinerary(data: CreateItineraryData): Promise<Itinerary> {
        return this.request<Itinerary>('/itineraries', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    async updateItinerary(id: string, data: Partial<CreateItineraryData>): Promise<Itinerary> {
        return this.request<Itinerary>(`/itineraries/${id}`, {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    async deleteItinerary(id: string): Promise<void> {
        await this.request(`/itineraries/${id}`, { method: 'DELETE' });
    }

    // Activities
    async createActivity(data: CreateActivityData): Promise<Activity> {
        return this.request<Activity>('/activities', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    async getActivity(id: string): Promise<Activity> {
        return this.request<Activity>(`/activities/${id}`);
    }

    async updateActivity(id: string, data: UpdateActivityData): Promise<Activity> {
        return this.request<Activity>(`/activities/${id}`, {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    async deleteActivity(id: string): Promise<void> {
        await this.request(`/activities/${id}`, { method: 'DELETE' });
    }

    async reorderActivity(itineraryId: string, data: ReorderActivityData): Promise<Activity> {
        return this.request<Activity>('/activities/reorder', {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    async getWishlistActivities(travelId: string): Promise<Activity[]> {
        return this.request<Activity[]>(`/activities/travel/${travelId}/wishlist`);
    }

    async assignActivity(activityId: string, itineraryId: string | null): Promise<Activity> {
        return this.request<Activity>(`/activities/${activityId}/assign`, {
            method: 'PATCH',
            body: JSON.stringify({ itineraryId }),
        });
    }

    // Comments
    async getActivityComments(activityId: string): Promise<ActivityComment[]> {
        return this.request<ActivityComment[]>(`/comments/activity/${activityId}`);
    }

    async createComment(activityId: string, content: string): Promise<ActivityComment> {
        return this.request<ActivityComment>(`/comments/activity/${activityId}`, {
            method: 'POST',
            body: JSON.stringify({ content }),
        });
    }

    async deleteComment(commentId: string): Promise<void> {
        await this.request(`/comments/${commentId}`, { method: 'DELETE' });
    }

    // Todos
    async getTodos(travelId: string): Promise<Todo[]> {
        return this.request<Todo[]>(`/todos?travelId=${travelId}`);
    }

    async createTodo(data: CreateTodoData): Promise<Todo> {
        return this.request<Todo>('/todos', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }

    async updateTodo(id: string, data: UpdateTodoData): Promise<Todo> {
        return this.request<Todo>(`/todos/${id}`, {
            method: 'PATCH',
            body: JSON.stringify(data),
        });
    }

    async deleteTodo(id: string): Promise<void> {
        await this.request(`/todos/${id}`, { method: 'DELETE' });
    }
}

export const api = new ApiClient();
