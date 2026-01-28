"use client";

import { useState } from "react";
import { X } from "lucide-react";
import Image from "next/image";

interface OpenInAppBannerProps {
  username: string;
}

export function OpenInAppBanner({ username }: OpenInAppBannerProps) {
  const [dismissed, setDismissed] = useState(false);

  if (dismissed) return null;

  return (
    <div className="sticky top-0 z-50 flex items-center gap-3 border-b border-gray-100 bg-white/90 px-4 py-2.5 backdrop-blur-sm">
      <Image
        src="/icon.png"
        alt="Triplly"
        width={32}
        height={32}
        className="rounded-lg"
      />
      <div className="flex-1">
        <p className="text-sm font-semibold text-gray-900">Triplly</p>
        <p className="text-xs text-gray-500">Travel together</p>
      </div>
      <a
        href={`triplly://profile/${username}`}
        className="rounded-full bg-emerald-500 px-4 py-1.5 text-sm font-semibold text-white"
      >
        Open
      </a>
      <button
        onClick={() => setDismissed(true)}
        className="p-1 text-gray-400"
        aria-label="Dismiss"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
}
