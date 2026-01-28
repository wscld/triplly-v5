import Image from "next/image";

interface ProfileHeaderProps {
  name: string;
  username: string;
  profilePhotoUrl: string | null;
}

export function ProfileHeader({
  name,
  username,
  profilePhotoUrl,
}: ProfileHeaderProps) {
  const initials = name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className="flex flex-col items-center gap-3 py-6">
      {profilePhotoUrl ? (
        <Image
          src={profilePhotoUrl}
          alt={name}
          width={96}
          height={96}
          className="h-24 w-24 rounded-full object-cover"
        />
      ) : (
        <div className="flex h-24 w-24 items-center justify-center rounded-full bg-emerald-100 text-2xl font-bold text-emerald-600">
          {initials}
        </div>
      )}

      <div className="text-center">
        <h1 className="text-xl font-bold text-gray-900">{name}</h1>
        <p className="text-sm font-medium text-emerald-600">@{username}</p>
      </div>
    </div>
  );
}
