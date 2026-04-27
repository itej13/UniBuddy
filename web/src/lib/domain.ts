import type { Assignment, AttendanceRecord, Subject } from "@prisma/client";

export const attendanceStatuses = ["present", "absent", "cancelled", "holiday"] as const;
export type AttendanceStatus = (typeof attendanceStatuses)[number];

export const submissionStates = [
  "new",
  "created",
  "turnedIn",
  "returned",
  "reclaimedByStudent",
  "unknown",
] as const;

export const weekdays = [
  { raw: 2, short: "Mon", full: "Monday" },
  { raw: 3, short: "Tue", full: "Tuesday" },
  { raw: 4, short: "Wed", full: "Wednesday" },
  { raw: 5, short: "Thu", full: "Thursday" },
  { raw: 6, short: "Fri", full: "Friday" },
  { raw: 7, short: "Sat", full: "Saturday" },
] as const;

export function classroomWeekday(date = new Date()) {
  const jsDay = date.getDay();
  return jsDay === 0 ? 1 : jsDay + 1;
}

export function minutesToTime(minutes: number) {
  const hour = Math.floor(minutes / 60);
  const minute = minutes % 60;
  return new Intl.DateTimeFormat("en", {
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(2024, 0, 1, hour, minute));
}

export function timeToMinutes(value: string) {
  const [hour, minute] = value.split(":").map(Number);
  return (hour || 0) * 60 + (minute || 0);
}

export function dateOnly(value: string | Date) {
  const date = typeof value === "string" ? new Date(`${value}T00:00:00`) : value;
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function attendanceSummary(subject: Subject, records: AttendanceRecord[]) {
  const subjectRecords = records.filter((record) => record.subjectId === subject.id);
  return {
    present: subjectRecords.filter((record) => record.status === "present").length,
    absent: subjectRecords.filter((record) => record.status === "absent").length,
    cancelled: subjectRecords.filter((record) => record.status === "cancelled").length,
    holiday: subjectRecords.filter((record) => record.status === "holiday").length,
  };
}

export function attendancePercentage(subject: Subject, records: AttendanceRecord[]) {
  const counted = records.filter(
    (record) =>
      record.subjectId === subject.id &&
      (record.status === "present" || record.status === "absent"),
  );
  if (counted.length === 0) return 0;
  return counted.filter((record) => record.status === "present").length / counted.length;
}

export function averageAttendance(subjects: Subject[], records: AttendanceRecord[]) {
  if (subjects.length === 0) return 0;
  return (
    subjects.reduce((total, subject) => total + attendancePercentage(subject, records), 0) /
    subjects.length
  );
}

export function submissionTitle(state: string) {
  switch (state) {
    case "new":
      return "New";
    case "created":
      return "Assigned";
    case "turnedIn":
      return "Turned in";
    case "returned":
      return "Returned";
    case "reclaimedByStudent":
      return "Reclaimed";
    default:
      return "Unknown";
  }
}

export function isComplete(assignment: Pick<Assignment, "submissionState">) {
  return assignment.submissionState === "turnedIn" || assignment.submissionState === "returned";
}

export function percent(value: number) {
  return new Intl.NumberFormat("en", { style: "percent", maximumFractionDigits: 0 }).format(value);
}
