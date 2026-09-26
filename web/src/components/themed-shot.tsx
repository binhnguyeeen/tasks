import type { Screenshot } from "@/lib/screens";
import { cn } from "@/lib/utils";

export function ThemedShot({
  shot,
  className,
  priority = false,
}: {
  shot: Screenshot;
  className?: string;
  priority?: boolean;
}) {
  const shared = {
    alt: shot.alt,
    width: shot.width,
    height: shot.height,
    decoding: "async" as const,
    loading: priority ? ("eager" as const) : ("lazy" as const),
  };
  return (
    <>
      <img src={shot.light} {...shared} className={cn("h-auto w-full dark:hidden", className)} />
      <img src={shot.dark} {...shared} className={cn("hidden h-auto w-full dark:block", className)} />
    </>
  );
}
