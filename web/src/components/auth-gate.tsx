import {
  BookOpenCheck,
  CalendarCheck2,
  CheckCircle2,
  CircleGauge,
  Clock3,
  GraduationCap,
  Inbox,
  LayoutDashboard,
  Link2,
  RefreshCw,
  ShieldCheck,
  Sparkles,
  Table2,
} from "lucide-react";
import { signInWithGoogle } from "@/lib/actions";

const highlights = [
  {
    icon: Table2,
    title: "Build your week once",
    body: "Create a clean timetable for every subject, room, and class slot so your day is readable at a glance.",
  },
  {
    icon: CalendarCheck2,
    title: "Track attendance without math",
    body: "Log present, absent, cancelled, or holiday statuses and keep subject percentages visible before they become urgent.",
  },
  {
    icon: Inbox,
    title: "Catch Classroom work early",
    body: "Sync Google Classroom courses and coursework so pending submissions live beside the rest of college life.",
  },
];

const workflow = [
  "Connect Google Classroom",
  "Add subjects and slots",
  "Review the daily dashboard",
  "Keep attendance current",
];

const previewRows = [
  { subject: "Data Structures", time: "09:00 - 10:00", room: "A-204", color: "#2563eb" },
  { subject: "Linear Algebra", time: "11:00 - 12:00", room: "B-112", color: "#059669" },
  { subject: "Design Lab", time: "14:00 - 16:00", room: "Studio 3", color: "#e11d48" },
];

const stats = [
  { label: "Today", value: "3", detail: "classes" },
  { label: "Pending", value: "5", detail: "submissions" },
  { label: "Attendance", value: "86%", detail: "average" },
];

export function AuthGate() {
  return (
    <main className="min-h-screen overflow-hidden bg-[#f6f3ee] text-stone-950">
      <section className="relative isolate px-4 py-4 sm:px-6 lg:px-8">
        <div className="absolute inset-x-0 top-0 -z-10 h-[560px] bg-[linear-gradient(135deg,rgba(219,234,254,0.72),rgba(255,255,255,0.9)_44%,rgba(209,250,229,0.5)_100%)]" />

        <nav className="mx-auto flex max-w-7xl items-center justify-between rounded-lg border border-stone-200/80 bg-white/82 px-3 py-3 shadow-sm backdrop-blur md:px-4">
          <div className="flex items-center gap-3">
            <div className="grid size-10 place-items-center rounded-md bg-blue-600 text-white shadow-sm shadow-blue-900/20">
              <BookOpenCheck size={21} />
            </div>
            <div>
              <div className="text-sm font-semibold text-stone-950">UniBuddy</div>
              <div className="text-xs font-medium text-stone-500">Student workspace</div>
            </div>
          </div>
          <form action={signInWithGoogle}>
            <button className="inline-flex h-10 items-center justify-center rounded-md bg-stone-950 px-4 text-sm font-semibold text-white shadow-sm transition hover:bg-stone-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
              <span>Sign in</span>
              <span className="ml-1 hidden sm:inline">with Google</span>
            </button>
          </form>
        </nav>

        <div className="mx-auto grid max-w-7xl gap-10 pb-16 pt-14 lg:grid-cols-[0.92fr_1.08fr] lg:items-center lg:pb-24 lg:pt-20">
          <div className="max-w-2xl">
            <h1 className="max-w-3xl text-5xl font-semibold leading-[1.02] text-stone-950 sm:text-6xl lg:text-7xl">
              College feels calmer when everything has one home.
            </h1>
            <p className="mt-6 max-w-xl text-lg leading-8 text-stone-600">
              UniBuddy brings your timetable, attendance, subjects, and Google Classroom submissions into a focused web workspace built for everyday student rhythm.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <form action={signInWithGoogle}>
                <button className="inline-flex h-12 w-full items-center justify-center gap-2 rounded-md bg-blue-600 px-5 text-sm font-semibold text-white shadow-lg shadow-blue-600/20 transition hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 sm:w-auto">
                  <Sparkles size={17} />
                  Start with Google
                </button>
              </form>
              <a
                href="#how-it-helps"
                className="inline-flex h-12 items-center justify-center rounded-md border border-stone-300 bg-white/80 px-5 text-sm font-semibold text-stone-800 shadow-sm transition hover:border-stone-400 hover:bg-white"
              >
                See how it helps
              </a>
            </div>
            <div className="mt-8 grid max-w-xl grid-cols-3 gap-3">
              {stats.map((stat) => (
                <div key={stat.label} className="rounded-lg border border-stone-200 bg-white/80 p-3 shadow-sm backdrop-blur">
                  <div className="text-2xl font-semibold text-stone-950">{stat.value}</div>
                  <div className="mt-1 text-xs font-medium uppercase text-stone-500">{stat.label}</div>
                  <div className="mt-0.5 text-xs text-stone-400">{stat.detail}</div>
                </div>
              ))}
            </div>
          </div>

          <DashboardPreview />
        </div>
      </section>

      <section id="how-it-helps" className="border-y border-stone-200 bg-white px-4 py-16 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-7xl">
          <div className="grid gap-8 lg:grid-cols-[0.78fr_1.22fr] lg:items-end">
            <div>
              <h2 className="text-3xl font-semibold text-stone-950 sm:text-4xl">
                Designed for the parts of college that usually scatter.
              </h2>
              <p className="mt-4 text-base leading-7 text-stone-600">
                UniBuddy is not another place to dump notes. It is the operating layer for your classes, deadlines, and attendance decisions.
              </p>
            </div>
            <div className="grid gap-3 md:grid-cols-3">
              {highlights.map((item) => {
                const Icon = item.icon;
                return (
                  <article key={item.title} className="rounded-lg border border-stone-200 bg-[#fbfaf7] p-5 shadow-sm">
                    <div className="mb-5 grid size-11 place-items-center rounded-md bg-blue-50 text-blue-700">
                      <Icon size={21} />
                    </div>
                    <h3 className="text-base font-semibold text-stone-950">{item.title}</h3>
                    <p className="mt-3 text-sm leading-6 text-stone-600">{item.body}</p>
                  </article>
                );
              })}
            </div>
          </div>
        </div>
      </section>

      <section className="px-4 py-16 sm:px-6 lg:px-8">
        <div className="mx-auto grid max-w-7xl gap-8 lg:grid-cols-[1fr_0.95fr] lg:items-center">
          <div className="rounded-lg border border-stone-200 bg-stone-950 p-5 text-white shadow-xl shadow-stone-950/10 sm:p-7">
            <div className="flex flex-col gap-5 md:flex-row md:items-start md:justify-between">
              <div>
                <h2 className="text-3xl font-semibold sm:text-4xl">A dashboard that answers the next question.</h2>
                <p className="mt-4 max-w-2xl text-sm leading-6 text-stone-300">
                  Open UniBuddy and see what matters now: today&apos;s schedule, pending coursework, attendance health, and your weekly structure.
                </p>
              </div>
              <div className="inline-flex shrink-0 items-center gap-2 rounded-md border border-white/10 bg-white/10 px-3 py-2 text-xs font-medium text-stone-200">
                <CircleGauge size={15} />
                Ready for class
              </div>
            </div>
            <div className="mt-8 grid gap-3 md:grid-cols-3">
              {[
                ["Dashboard", LayoutDashboard],
                ["Timetable", Table2],
                ["Attendance", CalendarCheck2],
              ].map(([label, Icon]) => (
                <div key={label as string} className="rounded-md border border-white/10 bg-white/[0.06] p-4">
                  <Icon className="text-blue-300" size={20} />
                  <div className="mt-4 text-sm font-semibold">{label as string}</div>
                  <div className="mt-1 h-2 overflow-hidden rounded-full bg-white/10">
                    <div className="h-full w-2/3 rounded-full bg-blue-400" />
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="grid gap-3">
            {workflow.map((item, index) => (
              <div key={item} className="flex items-center gap-4 rounded-lg border border-stone-200 bg-white p-4 shadow-sm">
                <div className="grid size-10 shrink-0 place-items-center rounded-md bg-[#f7f4ef] text-sm font-semibold text-stone-700">
                  {index + 1}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="text-sm font-semibold text-stone-950">{item}</div>
                  <div className="mt-1 text-sm text-stone-500">
                    {index === 0 ? "Bring courses and assignments into the workspace." : null}
                    {index === 1 ? "Shape the timetable around the way your college actually runs." : null}
                    {index === 2 ? "Know what is next before the day starts moving." : null}
                    {index === 3 ? "Keep percentages current with quick, honest logs." : null}
                  </div>
                </div>
                <CheckCircle2 className="text-emerald-600" size={19} />
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="px-4 pb-6 sm:px-6 lg:px-8">
        <div className="mx-auto max-w-7xl rounded-lg border border-blue-200 bg-blue-600 p-6 text-white shadow-xl shadow-blue-600/20 sm:p-8">
          <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-2xl font-semibold sm:text-3xl">Bring your semester into focus.</h2>
              <p className="mt-3 max-w-2xl text-sm leading-6 text-blue-50">
                Sign in with Google to start syncing Classroom, then build the subjects and timetable that make UniBuddy yours.
              </p>
            </div>
            <form action={signInWithGoogle}>
              <button className="inline-flex h-12 w-full items-center justify-center gap-2 rounded-md bg-white px-5 text-sm font-semibold text-blue-700 shadow-sm transition hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-white/80 focus:ring-offset-2 focus:ring-offset-blue-600 sm:w-auto">
                <ShieldCheck size={17} />
                Sign in with Google
              </button>
            </form>
          </div>
        </div>
      </section>
    </main>
  );
}

function DashboardPreview() {
  return (
    <div className="relative">
      <div className="absolute -inset-3 -z-10 rounded-[1.25rem] bg-stone-950/5 blur-2xl" />
      <div className="overflow-hidden rounded-lg border border-stone-200 bg-white shadow-2xl shadow-stone-950/12">
        <div className="grid border-b border-stone-200 bg-stone-950 text-white md:grid-cols-[190px_1fr]">
          <div className="border-b border-white/10 p-4 md:border-b-0 md:border-r">
            <div className="flex items-center gap-3">
              <div className="grid size-9 place-items-center rounded-md bg-blue-500">
                <BookOpenCheck size={19} />
              </div>
              <div>
                <div className="text-sm font-semibold">UniBuddy</div>
                <div className="text-xs text-stone-400">Student workspace</div>
              </div>
            </div>
            <div className="mt-7 space-y-2">
              {[
                [LayoutDashboard, "Dashboard", true],
                [GraduationCap, "Subjects", false],
                [Table2, "Timetable", false],
                [Inbox, "Submissions", false],
              ].map(([Icon, label, active]) => (
                <div
                  key={label as string}
                  className={`flex h-9 items-center gap-2 rounded-md px-3 text-xs font-medium ${
                    active ? "bg-white text-stone-950" : "text-stone-300"
                  }`}
                >
                  <Icon size={15} />
                  {label as string}
                </div>
              ))}
            </div>
          </div>
          <div className="bg-[#f7f4ef] p-4 text-stone-950">
            <div className="flex flex-col gap-3 border-b border-stone-200 pb-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <div className="text-xs font-medium uppercase text-stone-500">Wednesday, Apr 29</div>
                <div className="mt-1 text-xl font-semibold">Welcome back, Tejas</div>
              </div>
              <div className="inline-flex w-fit items-center gap-2 rounded-md bg-blue-600 px-3 py-2 text-xs font-semibold text-white">
                <RefreshCw size={14} />
                Sync
              </div>
            </div>

            <div className="mt-4 grid gap-3 sm:grid-cols-3">
              {stats.map((stat) => (
                <div key={stat.label} className="rounded-lg border border-stone-200 bg-white p-3">
                  <div className="text-xs font-semibold text-stone-500">{stat.label}</div>
                  <div className="mt-2 text-2xl font-semibold">{stat.value}</div>
                  <div className="mt-1 text-xs text-stone-400">{stat.detail}</div>
                </div>
              ))}
            </div>

            <div className="mt-4 grid gap-3 lg:grid-cols-[1fr_0.8fr]">
              <div className="rounded-lg border border-stone-200 bg-white p-3">
                <div className="mb-3 flex items-center justify-between">
                  <div className="text-sm font-semibold">Today&apos;s Classes</div>
                  <Clock3 size={15} className="text-stone-400" />
                </div>
                <div className="space-y-2">
                  {previewRows.map((row) => (
                    <div key={row.subject} className="flex items-center gap-3 rounded-md border border-stone-100 bg-stone-50 p-2">
                      <div className="grid size-8 place-items-center rounded-md" style={{ background: `${row.color}18`, color: row.color }}>
                        <BookOpenCheck size={15} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="truncate text-xs font-semibold text-stone-900">{row.subject}</div>
                        <div className="text-[11px] text-stone-500">
                          {row.time} | {row.room}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="rounded-lg border border-stone-200 bg-white p-3">
                <div className="mb-3 flex items-center justify-between">
                  <div className="text-sm font-semibold">Classroom</div>
                  <Link2 size={15} className="text-stone-400" />
                </div>
                <div className="space-y-3">
                  <ProgressRow label="DBMS worksheet" value="Due today" tone="bg-amber-400" />
                  <ProgressRow label="Lab journal" value="Tomorrow" tone="bg-blue-500" />
                  <ProgressRow label="Seminar notes" value="Submitted" tone="bg-emerald-500" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ProgressRow({ label, value, tone }: { label: string; value: string; tone: string }) {
  return (
    <div>
      <div className="mb-1 flex justify-between gap-3 text-xs">
        <span className="font-medium text-stone-800">{label}</span>
        <span className="text-stone-500">{value}</span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-stone-100">
        <div className={`h-full w-2/3 rounded-full ${tone}`} />
      </div>
    </div>
  );
}
