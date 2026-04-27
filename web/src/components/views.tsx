import Link from "next/link";
import {
  CalendarDays,
  CheckCircle2,
  ExternalLink,
  GraduationCap,
  Inbox,
  Plus,
  Trash2,
  XCircle,
} from "lucide-react";
import { AppShell } from "@/components/app-shell";
import { AuthGate } from "@/components/auth-gate";
import { EmptyState, Field, inputClass, Panel, primaryButtonClass, smallButtonClass } from "@/components/ui";
import {
  attendancePercentage,
  averageAttendance,
  classroomWeekday,
  isComplete,
  minutesToTime,
  percent,
  submissionTitle,
  weekdays,
} from "@/lib/domain";
import { createSubject, createTimetableSlot, deleteSubject, deleteTimetableSlot, markAttendance, signOutOfApp, updateSubject } from "@/lib/actions";
import { getAppData } from "@/lib/data";

type AppData = NonNullable<Awaited<ReturnType<typeof getAppData>>>;

export async function AppView({ active }: { active: "dashboard" | "subjects" | "timetable" | "submissions" | "attendance" | "settings" }) {
  const data = await getAppData();
  if (!data?.user) return <AuthGate />;

  return (
    <AppShell active={active} user={data.user}>
      {active === "dashboard" ? <Dashboard data={data} /> : null}
      {active === "subjects" ? <Subjects data={data} /> : null}
      {active === "timetable" ? <Timetable data={data} /> : null}
      {active === "submissions" ? <Submissions data={data} /> : null}
      {active === "attendance" ? <Attendance data={data} /> : null}
      {active === "settings" ? <SettingsView data={data} /> : null}
    </AppShell>
  );
}

function Dashboard({ data }: { data: AppData }) {
  const todaySlots = data.timetableSlots.filter((slot) => slot.weekday === classroomWeekday());
  const pending = data.assignments.filter((assignment) => !isComplete(assignment));
  const upcoming = pending.slice(0, 6);
  const attendanceAverage = averageAttendance(data.subjects, data.attendanceRecords);

  return (
    <div className="grid gap-5">
      {data.subjects.length === 0 ? <OnboardingStrip /> : null}
      {data.user?.lastSyncError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {data.user.lastSyncError}
        </div>
      ) : null}
      {data.user?.lastSyncStatus ? (
        <div className="rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700">
          {data.user.lastSyncStatus}
        </div>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Metric label="Subjects" value={String(data.subjects.length)} detail="Active courses" tone="blue" />
        <Metric label="Today" value={`${todaySlots.length}`} detail="Classes scheduled" tone="green" />
        <Metric label="Pending" value={String(pending.length)} detail="Classroom submissions" tone="amber" />
        <Metric label="Attendance" value={percent(attendanceAverage)} detail="Average across subjects" tone="coral" />
      </div>

      <div className="grid gap-5 xl:grid-cols-[1fr_1fr]">
        <Panel title="Today's Classes" eyebrow="Schedule">
          <div className="space-y-3">
            {todaySlots.length === 0 ? (
              <EmptyState>No timetable slots for today.</EmptyState>
            ) : (
              todaySlots.map((slot) => <SlotRow key={slot.id} slot={slot} />)
            )}
          </div>
        </Panel>
        <Panel title="Upcoming Submissions" eyebrow="Classroom">
          <div className="space-y-3">
            {upcoming.length === 0 ? (
              <EmptyState>No pending submissions from the last sync.</EmptyState>
            ) : (
              upcoming.map((assignment) => <AssignmentRow key={assignment.id} assignment={assignment} />)
            )}
          </div>
        </Panel>
      </div>

      <div className="grid gap-5 xl:grid-cols-[1.1fr_0.9fr]">
        <Panel title="Subject Analytics" eyebrow="Attendance">
          <SubjectAnalytics data={data} />
        </Panel>
        <Panel title="Weekly Timetable" eyebrow="Preview">
          <TimetableGrid data={data} compact />
        </Panel>
      </div>
    </div>
  );
}

function Metric({ label, value, detail, tone }: { label: string; value: string; detail: string; tone: "blue" | "green" | "amber" | "coral" }) {
  const tones = {
    blue: "bg-blue-50 text-blue-700",
    green: "bg-emerald-50 text-emerald-700",
    amber: "bg-amber-50 text-amber-700",
    coral: "bg-rose-50 text-rose-700",
  };
  return (
    <div className="rounded-lg border border-stone-200 bg-white p-4 shadow-sm">
      <div className={`mb-4 inline-flex rounded-md px-2 py-1 text-xs font-semibold ${tones[tone]}`}>
        {label}
      </div>
      <div className="text-3xl font-semibold tracking-tight text-stone-950">{value}</div>
      <div className="mt-1 text-sm text-stone-500">{detail}</div>
    </div>
  );
}

function OnboardingStrip() {
  return (
    <section className="rounded-lg border border-blue-200 bg-blue-50 p-4">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="font-semibold text-blue-950">Set up your first subject</h2>
          <p className="text-sm text-blue-800">Add subjects and timetable slots, then sync Classroom when credentials are ready.</p>
        </div>
        <Link className={primaryButtonClass} href="/subjects">
          Start setup
        </Link>
      </div>
    </section>
  );
}

function Subjects({ data }: { data: AppData }) {
  return (
    <div className="grid gap-5 xl:grid-cols-[380px_1fr]">
      <Panel title="Add Subject" eyebrow="Setup">
        <SubjectForm />
      </Panel>
      <Panel title="Subjects" eyebrow={`${data.subjects.length} active`}>
        <div className="space-y-4">
          {data.subjects.length === 0 ? (
            <EmptyState>Add your first subject to start tracking attendance.</EmptyState>
          ) : (
            data.subjects.map((subject) => (
              <form key={subject.id} action={updateSubject} className="rounded-lg border border-stone-200 p-4">
                <input type="hidden" name="id" value={subject.id} />
                <div className="grid gap-3 md:grid-cols-[1fr_140px_100px]">
                  <Field label="Name">
                    <input className={inputClass} name="name" defaultValue={subject.name} />
                  </Field>
                  <Field label="Code">
                    <input className={inputClass} name="code" defaultValue={subject.code} />
                  </Field>
                  <Field label="Credits">
                    <input className={inputClass} name="credits" type="number" min="0" max="10" defaultValue={subject.credits} />
                  </Field>
                </div>
                <div className="mt-3 grid gap-3 md:grid-cols-[1fr_auto_auto] md:items-end">
                  <Field label="Classroom Course">
                    <select className={inputClass} name="classroomCourseId" defaultValue={subject.classroomCourseId ?? ""}>
                      <option value="">Not linked</option>
                      {data.classroomCourses.map((course) => (
                        <option key={course.id} value={course.classroomId}>
                          {course.section ? `${course.name} · ${course.section}` : course.name}
                        </option>
                      ))}
                    </select>
                  </Field>
                  <button className={smallButtonClass}>Save</button>
                  <button formAction={deleteSubject} className="inline-flex h-9 items-center justify-center gap-2 rounded-md border border-red-200 bg-white px-3 text-sm font-medium text-red-600 transition hover:bg-red-50">
                    <Trash2 size={15} />
                    Delete
                  </button>
                </div>
              </form>
            ))
          )}
        </div>
      </Panel>
    </div>
  );
}

function SubjectForm() {
  return (
    <form action={createSubject} className="grid gap-3">
      <Field label="Subject name">
        <input className={inputClass} name="name" placeholder="Data Structures" required />
      </Field>
      <Field label="Subject code">
        <input className={inputClass} name="code" placeholder="CS201" />
      </Field>
      <Field label="Credits">
        <input className={inputClass} name="credits" type="number" min="0" max="10" defaultValue="3" />
      </Field>
      <button className={primaryButtonClass}>
        <Plus size={16} />
        Add Subject
      </button>
    </form>
  );
}

function Timetable({ data }: { data: AppData }) {
  return (
    <div className="grid gap-5">
      <Panel title="Add Timetable Slots" eyebrow="Schedule builder">
        <TimetableForm data={data} />
      </Panel>
      <Panel title="Weekly Table" eyebrow="Monday to Saturday">
        <TimetableGrid data={data} />
      </Panel>
    </div>
  );
}

function TimetableForm({ data }: { data: AppData }) {
  return (
    <form action={createTimetableSlot} className="grid gap-3 lg:grid-cols-[1.1fr_1.4fr_130px_130px_120px_auto] lg:items-end">
      <Field label="Subject">
        <select className={inputClass} name="subjectId" required>
          <option value="">Choose subject</option>
          {data.subjects.map((subject) => (
            <option key={subject.id} value={subject.id}>
              {subject.name}
            </option>
          ))}
        </select>
      </Field>
      <div>
        <div className="mb-1 text-sm font-medium text-stone-700">Days</div>
        <div className="flex flex-wrap gap-2">
          {weekdays.map((day) => (
            <label key={day.raw} className="inline-flex h-10 items-center gap-2 rounded-md border border-stone-200 bg-white px-3 text-sm">
              <input type="checkbox" name="days" value={day.raw} defaultChecked={day.raw === 2} />
              {day.short}
            </label>
          ))}
        </div>
      </div>
      <Field label="Start">
        <input className={inputClass} type="time" name="startTime" defaultValue="09:00" />
      </Field>
      <Field label="End">
        <input className={inputClass} type="time" name="endTime" defaultValue="10:00" />
      </Field>
      <Field label="Room">
        <input className={inputClass} name="room" placeholder="A-204" />
      </Field>
      <button className={primaryButtonClass}>Add Slots</button>
    </form>
  );
}

function TimetableGrid({ data, compact = false }: { data: AppData; compact?: boolean }) {
  if (data.timetableSlots.length === 0) return <EmptyState>Add timetable slots to see them here.</EmptyState>;

  return (
    <div className={`grid gap-3 ${compact ? "" : "md:grid-cols-2 xl:grid-cols-3"}`}>
      {weekdays.map((day) => {
        const slots = data.timetableSlots.filter((slot) => slot.weekday === day.raw);
        return (
          <div key={day.raw} className="rounded-lg border border-stone-200 bg-stone-50 p-3">
            <h3 className="mb-3 text-sm font-semibold text-stone-950">{day.full}</h3>
            <div className="space-y-2">
              {slots.length === 0 ? (
                <p className="text-sm text-stone-400">No classes</p>
              ) : (
                slots.map((slot) => <SlotRow key={slot.id} slot={slot} deletable={!compact} />)
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function SlotRow({ slot, deletable = false }: { slot: AppData["timetableSlots"][number]; deletable?: boolean }) {
  return (
    <div className="flex items-center gap-3 rounded-md border border-stone-200 bg-white p-3">
      <div className="grid size-9 place-items-center rounded-md" style={{ background: `${slot.subject.colorHex}18`, color: slot.subject.colorHex }}>
        <CalendarDays size={17} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-semibold text-stone-950">{slot.subject.name}</div>
        <div className="text-xs text-stone-500">
          {minutesToTime(slot.startMinutes)} - {minutesToTime(slot.endMinutes)}
          {slot.room ? ` · ${slot.room}` : ""}
        </div>
      </div>
      {deletable ? (
        <form action={deleteTimetableSlot}>
          <input type="hidden" name="id" value={slot.id} />
          <button className="grid size-8 place-items-center rounded-md text-stone-400 hover:bg-red-50 hover:text-red-600" aria-label="Delete slot">
            <Trash2 size={15} />
          </button>
        </form>
      ) : null}
    </div>
  );
}

function Attendance({ data }: { data: AppData }) {
  const today = new Date().toISOString().slice(0, 10);
  const todaySlots = data.timetableSlots.filter((slot) => slot.weekday === classroomWeekday());

  return (
    <div className="grid gap-5">
      <Panel title="Mark Attendance" eyebrow="Today">
        <div className="space-y-3">
          {todaySlots.length === 0 ? (
            <EmptyState>No timetable slots for today. Add slots from Timetable.</EmptyState>
          ) : (
            todaySlots.map((slot) => (
              <div key={slot.id} className="flex flex-col gap-3 rounded-lg border border-stone-200 p-3 md:flex-row md:items-center">
                <div className="flex-1">
                  <div className="font-semibold text-stone-950">{slot.subject.name}</div>
                  <div className="text-sm text-stone-500">{minutesToTime(slot.startMinutes)} - {minutesToTime(slot.endMinutes)}</div>
                </div>
                <div className="flex flex-wrap gap-2">
                  {[
                    ["present", CheckCircle2, "text-emerald-700"],
                    ["absent", XCircle, "text-red-600"],
                    ["cancelled", CalendarDays, "text-amber-700"],
                    ["holiday", GraduationCap, "text-blue-700"],
                  ].map(([status, Icon, color]) => (
                    <form key={status as string} action={markAttendance}>
                      <input type="hidden" name="subjectId" value={slot.subjectId} />
                      <input type="hidden" name="date" value={today} />
                      <input type="hidden" name="status" value={status as string} />
                      <button className={`${smallButtonClass} ${color}`}>
                        <Icon size={15} />
                        <span className="capitalize">{status as string}</span>
                      </button>
                    </form>
                  ))}
                </div>
              </div>
            ))
          )}
        </div>
      </Panel>
      <Panel title="Subject Analytics" eyebrow="Current record">
        <SubjectAnalytics data={data} />
      </Panel>
      <Panel title="History" eyebrow="Recent 30">
        <div className="space-y-2">
          {data.attendanceRecords.slice(0, 30).map((record) => {
            const subject = data.subjects.find((item) => item.id === record.subjectId);
            return (
              <div key={record.id} className="flex items-center justify-between rounded-md border border-stone-200 bg-white px-3 py-2 text-sm">
                <span className="font-medium">{subject?.name ?? "Unknown"}</span>
                <span className="text-stone-500">{record.date.toLocaleDateString()} · {record.status}</span>
              </div>
            );
          })}
          {data.attendanceRecords.length === 0 ? <EmptyState>No attendance marked yet.</EmptyState> : null}
        </div>
      </Panel>
    </div>
  );
}

function SubjectAnalytics({ data }: { data: AppData }) {
  if (data.subjects.length === 0) return <EmptyState>Add subjects to see attendance analytics.</EmptyState>;
  return (
    <div className="space-y-4">
      {data.subjects.map((subject) => {
        const value = attendancePercentage(subject, data.attendanceRecords);
        return (
          <div key={subject.id}>
            <div className="mb-2 flex justify-between gap-3 text-sm">
              <span className="font-medium text-stone-800">{subject.name}</span>
              <span className="text-stone-500">{percent(value)}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-stone-100">
              <div className="h-full rounded-full" style={{ width: `${value * 100}%`, background: subject.colorHex }} />
            </div>
          </div>
        );
      })}
    </div>
  );
}

function Submissions({ data }: { data: AppData }) {
  const now = new Date();
  const overdue = data.assignments.filter((item) => !isComplete(item) && item.dueDate && item.dueDate < now);
  const upcoming = data.assignments.filter((item) => !isComplete(item) && (!item.dueDate || item.dueDate >= now));
  const complete = data.assignments.filter(isComplete);
  return (
    <div className="grid gap-5">
      <SubmissionGroup title="Overdue" assignments={overdue} />
      <SubmissionGroup title="Upcoming" assignments={upcoming} />
      <SubmissionGroup title="Completed" assignments={complete} />
    </div>
  );
}

function SubmissionGroup({ title, assignments }: { title: string; assignments: AppData["assignments"] }) {
  return (
    <Panel title={title} eyebrow={`${assignments.length} items`}>
      <div className="space-y-3">
        {assignments.length === 0 ? (
          <EmptyState>Nothing here.</EmptyState>
        ) : (
          assignments.map((assignment) => <AssignmentRow key={assignment.id} assignment={assignment} />)
        )}
      </div>
    </Panel>
  );
}

function AssignmentRow({ assignment }: { assignment: AppData["assignments"][number] }) {
  return (
    <div className="flex items-start gap-3 rounded-md border border-stone-200 bg-white p-3">
      <div className="grid size-9 shrink-0 place-items-center rounded-md bg-amber-50 text-amber-700">
        <Inbox size={17} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-semibold text-stone-950">{assignment.title}</div>
        <div className="text-xs text-stone-500">
          {assignment.courseName}
          {assignment.dueDate ? ` · Due ${assignment.dueDate.toLocaleString()}` : ""}
        </div>
      </div>
      <span className="rounded-md bg-stone-100 px-2 py-1 text-xs font-medium text-stone-600">
        {submissionTitle(assignment.submissionState)}
      </span>
      {assignment.alternateLink ? (
        <a className="grid size-8 place-items-center rounded-md text-stone-500 hover:bg-stone-100" href={assignment.alternateLink} target="_blank" rel="noreferrer" aria-label="Open in Classroom">
          <ExternalLink size={15} />
        </a>
      ) : null}
    </div>
  );
}

function SettingsView({ data }: { data: AppData }) {
  return (
    <div className="grid gap-5 xl:grid-cols-2">
      <Panel title="Account" eyebrow="Google">
        <div className="space-y-4 text-sm text-stone-600">
          <p>{data.user?.email}</p>
          <p>Last sync: {data.user?.lastSyncAt ? data.user.lastSyncAt.toLocaleString() : "Not synced yet"}</p>
          <form action={signOutOfApp}>
            <button className={smallButtonClass}>Sign out</button>
          </form>
        </div>
      </Panel>
      <Panel title="Configuration" eyebrow="Local development">
        <div className="space-y-3 text-sm leading-6 text-stone-600">
          <p>Use Google web OAuth credentials with the Classroom API enabled.</p>
          <p>
            Required env vars live in <code>web/.env.local</code>: <code>GOOGLE_CLIENT_ID</code>,{" "}
            <code>GOOGLE_CLIENT_SECRET</code>, <code>AUTH_SECRET</code>, and <code>DATABASE_URL</code>.
          </p>
        </div>
      </Panel>
    </div>
  );
}
