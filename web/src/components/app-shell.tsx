import Link from "next/link";
import type { ReactNode } from "react";
import {
  BookOpenCheck,
  CalendarCheck,
  CircleGauge,
  GraduationCap,
  LayoutDashboard,
  Inbox,
  RefreshCw,
  Settings,
  Table2,
} from "lucide-react";
import { syncClassroom } from "@/lib/actions";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/subjects", label: "Subjects", icon: GraduationCap },
  { href: "/timetable", label: "Timetable", icon: Table2 },
  { href: "/submissions", label: "Submissions", icon: Inbox },
  { href: "/attendance", label: "Attendance", icon: CalendarCheck },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function AppShell({
  active,
  user,
  children,
}: {
  active: string;
  user: { name?: string | null; email?: string | null; image?: string | null };
  children: ReactNode;
}) {
  const today = new Intl.DateTimeFormat("en", {
    weekday: "long",
    month: "short",
    day: "numeric",
  }).format(new Date());

  return (
    <div className="min-h-screen p-3 text-stone-900 md:p-5">
      <div className="mx-auto grid min-h-[calc(100vh-24px)] max-w-[1500px] grid-cols-1 overflow-hidden rounded-lg border border-stone-200 bg-white shadow-sm md:min-h-[calc(100vh-40px)] md:grid-cols-[248px_1fr]">
        <aside className="border-b border-stone-200 bg-stone-950 text-white md:border-b-0 md:border-r">
          <div className="flex items-center justify-between gap-3 p-4 md:block md:p-5">
            <div className="flex items-center gap-3">
              <div className="grid size-10 place-items-center rounded-md bg-blue-500">
                <BookOpenCheck size={21} />
              </div>
              <div>
                <div className="font-semibold">UniBuddy</div>
                <div className="text-xs text-stone-400">Student workspace</div>
              </div>
            </div>
            <div className="hidden items-center gap-2 rounded-md border border-white/10 bg-white/5 px-3 py-2 text-xs text-stone-300 md:mt-6 md:flex">
              <CircleGauge size={15} />
              Ready for class
            </div>
          </div>
          <nav className="flex gap-1 overflow-x-auto px-3 pb-3 md:block md:space-y-1 md:px-3 md:pb-0">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = active === item.label.toLowerCase();
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex h-10 shrink-0 items-center gap-3 rounded-md px-3 text-sm transition ${
                    isActive
                      ? "bg-white text-stone-950"
                      : "text-stone-300 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  <Icon size={17} />
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </aside>
        <div className="min-w-0 bg-[#f7f4ef]">
          <header className="flex flex-col gap-4 border-b border-stone-200 bg-white/85 px-4 py-4 backdrop-blur md:flex-row md:items-center md:justify-between md:px-6">
            <div>
              <p className="text-xs font-medium uppercase tracking-[0.18em] text-stone-500">{today}</p>
              <h1 className="mt-1 text-2xl font-semibold tracking-tight text-stone-950">
                Welcome back{user.name ? `, ${user.name.split(" ")[0]}` : ""}
              </h1>
            </div>
            <div className="flex items-center gap-3">
              <form action={syncClassroom}>
                <button className="inline-flex h-10 items-center gap-2 rounded-md bg-blue-600 px-3 text-sm font-semibold text-white transition hover:bg-blue-700">
                  <RefreshCw size={16} />
                  Sync
                </button>
              </form>
              <div className="flex items-center gap-2 rounded-md border border-stone-200 bg-white px-2 py-1.5">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={user.image ?? `https://api.dicebear.com/8.x/initials/svg?seed=${user.email ?? "UniBuddy"}`}
                  alt=""
                  className="size-7 rounded-full bg-stone-100"
                />
                <span className="hidden max-w-40 truncate text-sm text-stone-600 sm:inline">
                  {user.email}
                </span>
              </div>
            </div>
          </header>
          <main className="p-4 md:p-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
