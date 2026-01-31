import { AppDataSource } from "../data-source.js";
import { TravelMember, MemberRole } from "../entities/TravelMember.js";
import { Itinerary } from "../entities/Itinerary.js";
import { Activity } from "../entities/Activity.js";
import { ActivityComment } from "../entities/ActivityComment.js";
import { Todo } from "../entities/Todo.js";

export interface Award {
  id: string;
  name: string;
  icon: string;
  description: string;
}

const AWARDS_CATALOG: Award[] = [
  // Travel Milestones
  { id: "first_steps", name: "First Steps", icon: "figure.walk", description: "Every journey begins with a single step" },
  { id: "wanderer", name: "Wanderer", icon: "map", description: "The world is calling, and you're answering" },
  { id: "globetrotter", name: "Globetrotter", icon: "globe.americas", description: "Stamps in your passport, stories in your heart" },
  { id: "world_explorer", name: "World Explorer", icon: "globe", description: "You've made the world your playground" },
  { id: "eternal_nomad", name: "Eternal Nomad", icon: "airplane.circle", description: "Home is wherever you unpack your bags" },
  // Solo & Social
  { id: "solo_adventurer", name: "Solo Adventurer", icon: "person.fill", description: "Brave enough to explore alone" },
  { id: "lone_wolf", name: "Lone Wolf", icon: "moon.stars", description: "A true independent spirit" },
  { id: "squad_goals", name: "Squad Goals", icon: "person.3.fill", description: "Everything's better with friends" },
  { id: "party_leader", name: "Party Leader", icon: "crown", description: "Leading the pack in style" },
  // Planning & Activity
  { id: "master_planner", name: "Master Planner", icon: "list.clipboard", description: "Every detail, perfectly planned" },
  { id: "activity_junkie", name: "Activity Junkie", icon: "bolt.fill", description: "Never a dull moment" },
  { id: "storyteller", name: "Storyteller", icon: "text.bubble", description: "Sharing the journey, one story at a time" },
  // Checklist
  { id: "checklister", name: "Checklister", icon: "checklist.checked", description: "Ticking off the list, one task at a time" },
];

function getAward(id: string): Award | undefined {
  return AWARDS_CATALOG.find((a) => a.id === id);
}

export async function computeUserAwards(userId: string): Promise<Award[]> {
  const memberRepo = AppDataSource.getRepository(TravelMember);
  const itineraryRepo = AppDataSource.getRepository(Itinerary);
  const activityRepo = AppDataSource.getRepository(Activity);
  const commentRepo = AppDataSource.getRepository(ActivityComment);

  // Get all travels where user is owner
  const ownedMemberships = await memberRepo.find({
    where: { userId, role: MemberRole.OWNER },
    relations: ["travel", "travel.members"],
  });

  const totalTravels = ownedMemberships.length;
  const unlocked: Award[] = [];

  // Travel milestones
  if (totalTravels >= 1) unlocked.push(getAward("first_steps")!);
  if (totalTravels >= 3) unlocked.push(getAward("wanderer")!);
  if (totalTravels >= 5) unlocked.push(getAward("globetrotter")!);
  if (totalTravels >= 10) unlocked.push(getAward("world_explorer")!);
  if (totalTravels >= 25) unlocked.push(getAward("eternal_nomad")!);

  // Solo & Social
  let soloTravelCount = 0;
  let maxMembers = 0;

  for (const membership of ownedMemberships) {
    const memberCount = membership.travel.members.length;
    if (memberCount === 1) soloTravelCount++;
    if (memberCount > maxMembers) maxMembers = memberCount;
  }

  if (soloTravelCount >= 1) unlocked.push(getAward("solo_adventurer")!);
  if (soloTravelCount >= 5) unlocked.push(getAward("lone_wolf")!);
  if (maxMembers >= 3) unlocked.push(getAward("squad_goals")!);
  if (maxMembers >= 5) unlocked.push(getAward("party_leader")!);

  // Planning: count itinerary days across owned travels
  const ownedTravelIds = ownedMemberships.map((m) => m.travelId);

  if (ownedTravelIds.length > 0) {
    const totalItineraryDays = await itineraryRepo
      .createQueryBuilder("itinerary")
      .where("itinerary.travelId IN (:...travelIds)", { travelIds: ownedTravelIds })
      .getCount();

    if (totalItineraryDays >= 10) unlocked.push(getAward("master_planner")!);

    // Activity count across owned travels
    const totalActivities = await activityRepo
      .createQueryBuilder("activity")
      .where("activity.travelId IN (:...travelIds)", { travelIds: ownedTravelIds })
      .getCount();

    if (totalActivities >= 50) unlocked.push(getAward("activity_junkie")!);
  }

  // Comments by user
  const totalComments = await commentRepo.count({ where: { userId } });
  if (totalComments >= 10) unlocked.push(getAward("storyteller")!);

  // Checklist: completed todos across owned travels
  if (ownedTravelIds.length > 0) {
    const todoRepo = AppDataSource.getRepository(Todo);
    const completedTodos = await todoRepo
      .createQueryBuilder("todo")
      .where("todo.travelId IN (:...travelIds)", { travelIds: ownedTravelIds })
      .andWhere("todo.isCompleted = :completed", { completed: true })
      .getCount();

    if (completedTodos >= 10) unlocked.push(getAward("checklister")!);
  }

  return unlocked;
}
