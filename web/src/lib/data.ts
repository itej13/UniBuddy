import { auth } from "@/auth";
import { prisma } from "@/lib/prisma";

export type AppViewName =
  | "dashboard"
  | "subjects"
  | "timetable"
  | "submissions"
  | "attendance"
  | "settings";

type AttendanceTotal = {
  subjectId: string;
  present: number;
  absent: number;
};

export async function currentUserId() {
  const session = await auth();
  return session?.user?.id ?? null;
}

export async function requireUserId() {
  const userId = await currentUserId();
  if (!userId) {
    throw new Error("Sign in before using UniBuddy.");
  }
  return userId;
}

async function getAttendanceTotals(userId: string): Promise<AttendanceTotal[]> {
  const rows = await prisma.attendanceRecord.groupBy({
    by: ["subjectId", "status"],
    where: { userId, status: { in: ["present", "absent"] } },
    _count: { _all: true },
  });

  const totals = new Map<string, AttendanceTotal>();
  for (const row of rows) {
    const total = totals.get(row.subjectId) ?? {
      subjectId: row.subjectId,
      present: 0,
      absent: 0,
    };
    total[row.status as "present" | "absent"] = row._count._all;
    totals.set(row.subjectId, total);
  }

  return [...totals.values()];
}

export async function getAppData(active: AppViewName) {
  const userId = await currentUserId();
  if (!userId) return null;

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return null;

  const baseData = {
    user,
    subjects: [],
    timetableSlots: [],
    attendanceRecords: [],
    attendanceTotals: [],
    classroomCourses: [],
    assignments: [],
  };

  switch (active) {
    case "dashboard": {
      const [subjects, timetableSlots, attendanceTotals, assignments] = await Promise.all([
        prisma.subject.findMany({ where: { userId }, orderBy: [{ name: "asc" }] }),
        prisma.timetableSlot.findMany({
          where: { userId },
          include: { subject: true },
          orderBy: [{ weekday: "asc" }, { startMinutes: "asc" }],
        }),
        getAttendanceTotals(userId),
        prisma.assignment.findMany({
          where: { userId },
          include: { subject: true },
          orderBy: [{ dueDate: "asc" }, { title: "asc" }],
        }),
      ]);
      return { ...baseData, subjects, timetableSlots, attendanceTotals, assignments };
    }
    case "subjects": {
      const [subjects, classroomCourses] = await Promise.all([
        prisma.subject.findMany({ where: { userId }, orderBy: [{ name: "asc" }] }),
        prisma.classroomCourse.findMany({
          where: { userId },
          orderBy: [{ name: "asc" }],
        }),
      ]);
      return { ...baseData, subjects, classroomCourses };
    }
    case "timetable": {
      const [subjects, timetableSlots] = await Promise.all([
        prisma.subject.findMany({ where: { userId }, orderBy: [{ name: "asc" }] }),
        prisma.timetableSlot.findMany({
          where: { userId },
          include: { subject: true },
          orderBy: [{ weekday: "asc" }, { startMinutes: "asc" }],
        }),
      ]);
      return { ...baseData, subjects, timetableSlots };
    }
    case "submissions": {
      const assignments = await prisma.assignment.findMany({
        where: { userId },
        include: { subject: true },
        orderBy: [{ dueDate: "asc" }, { title: "asc" }],
      });
      return { ...baseData, assignments };
    }
    case "attendance": {
      const [subjects, timetableSlots, attendanceTotals, attendanceRecords] = await Promise.all([
        prisma.subject.findMany({ where: { userId }, orderBy: [{ name: "asc" }] }),
        prisma.timetableSlot.findMany({
          where: { userId },
          include: { subject: true },
          orderBy: [{ weekday: "asc" }, { startMinutes: "asc" }],
        }),
        getAttendanceTotals(userId),
        prisma.attendanceRecord.findMany({
          where: { userId },
          orderBy: [{ date: "desc" }],
          take: 30,
        }),
      ]);
      return { ...baseData, subjects, timetableSlots, attendanceTotals, attendanceRecords };
    }
    case "settings":
      return baseData;
  }
}
