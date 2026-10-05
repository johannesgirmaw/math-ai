"use client";

import { useEffect } from "react";
import { toast } from "sonner";

export function SaveToast({ saved, published }: { saved?: string; published?: string }) {
  useEffect(() => {
    if (saved) toast("Saved");
    if (published) toast("Published");
  }, [saved, published]);
  return null;
}
