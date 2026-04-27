import { auth } from "@/auth";
import { prisma } from "@/lib/prisma";

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

export async function getAppData() {
  const userId = await currentUserId();
  if (!userId) return null;

  const [user, subjects, timetableSlots, attendanceRecords, classroomCourses, assignments] =
    await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.subject.findMany({ where: { userId }, orderBy: [{ name: "asc" }] }),
      prisma.timetableSlot.findMany({
        where: { userId },
        include: { subject: true },
        orderBy: [{ weekday: "asc" }, { startMinutes: "asc" }],
      }),
      prisma.attendanceRecord.findMany({
        where: { userId },
        orderBy: [{ date: "desc" }],
      }),
      prisma.classroomCourse.findMany({
        where: { userId },
        orderBy: [{ name: "asc" }],
      }),
      prisma.assignment.findMany({
        where: { userId },
        include: { subject: true },
        orderBy: [{ dueDate: "asc" }, { title: "asc" }],
      }),
    ]);

  return {
    user,
    subjects,
    timetableSlots,
    attendanceRecords,
    classroomCourses,
    assignments,
  };
}
