"use server";

import { revalidatePath } from "next/cache";
import { signIn, signOut } from "@/auth";
import { listCourses, listCourseWork, listSubmissions, resolvedDueDate, submissionState } from "@/lib/classroom";
import { attendanceStatuses, dateOnly, timeToMinutes } from "@/lib/domain";
import { prisma } from "@/lib/prisma";
import { requireUserId } from "@/lib/data";

const subjectColors = ["#2563EB", "#059669", "#EA580C", "#DC2626", "#7C3AED", "#0891B2"];

function formString(formData: FormData, key: string) {
  return String(formData.get(key) ?? "").trim();
}

function revalidateApp() {
  revalidatePath("/");
  revalidatePath("/dashboard");
  revalidatePath("/subjects");
  revalidatePath("/timetable");
  revalidatePath("/submissions");
  revalidatePath("/attendance");
  revalidatePath("/settings");
}

export async function signInWithGoogle() {
  await signIn("google", { redirectTo: "/dashboard" });
}

export async function signOutOfApp() {
  await signOut({ redirectTo: "/" });
}

export async function createSubject(formData: FormData) {
  const userId = await requireUserId();
  const name = formString(formData, "name");
  if (!name) return;

  const count = await prisma.subject.count({ where: { userId } });
  await prisma.subject.create({
    data: {
      userId,
      name,
      code: formString(formData, "code"),
      credits: Number(formData.get("credits") ?? 3),
      colorHex: subjectColors[count % subjectColors.length],
    },
  });
  revalidateApp();
}

export async function updateSubject(formData: FormData) {
  const userId = await requireUserId();
  const id = formString(formData, "id");
  const courseId = formString(formData, "classroomCourseId");
  const course = courseId
    ? await prisma.classroomCourse.findUnique({
        where: { userId_classroomId: { userId, classroomId: courseId } },
      })
    : null;

  await prisma.subject.update({
    where: { id, userId },
    data: {
      name: formString(formData, "name"),
      code: formString(formData, "code"),
      credits: Number(formData.get("credits") ?? 3),
      classroomCourseId: courseId || null,
      classroomCourseName: course?.section ? `${course.name} · ${course.section}` : course?.name ?? null,
    },
  });
  revalidateApp();
}

export async function deleteSubject(formData: FormData) {
  const userId = await requireUserId();
  const id = formString(formData, "id");
  await prisma.subject.delete({ where: { id, userId } });
  revalidateApp();
}

export async function createTimetableSlot(formData: FormData) {
  const userId = await requireUserId();
  const subjectId = formString(formData, "subjectId");
  const days = formData.getAll("days").map(Number);
  const startMinutes = timeToMinutes(formString(formData, "startTime") || "09:00");
  const endMinutes = timeToMinutes(formString(formData, "endTime") || "10:00");
  const room = formString(formData, "room");

  if (!subjectId || days.length === 0 || endMinutes <= startMinutes) return;

  for (const weekday of days) {
    const duplicate = await prisma.timetableSlot.findFirst({
      where: { userId, subjectId, weekday, startMinutes, endMinutes },
    });
    if (!duplicate) {
      await prisma.timetableSlot.create({
        data: { userId, subjectId, weekday, startMinutes, endMinutes, room },
      });
    }
  }
  revalidateApp();
}

export async function deleteTimetableSlot(formData: FormData) {
  const userId = await requireUserId();
  const id = formString(formData, "id");
  await prisma.timetableSlot.delete({ where: { id, userId } });
  revalidateApp();
}

export async function markAttendance(formData: FormData) {
  const userId = await requireUserId();
  const subjectId = formString(formData, "subjectId");
  const date = dateOnly(formString(formData, "date"));
  const status = formString(formData, "status");

  if (!subjectId || !attendanceStatuses.includes(status as never)) return;

  await prisma.attendanceRecord.upsert({
    where: { userId_subjectId_date: { userId, subjectId, date } },
    update: { status },
    create: { userId, subjectId, date, status },
  });
  revalidateApp();
}

export async function syncClassroom() {
  const userId = await requireUserId();
  const account = await prisma.account.findFirst({
    where: { userId, provider: "google" },
    orderBy: { id: "desc" },
  });

  if (!account?.access_token) {
    await prisma.user.update({
      where: { id: userId },
      data: { lastSyncError: "Google did not provide an access token. Sign out and sign in again.", lastSyncStatus: null },
    });
    revalidateApp();
    return;
  }

  try {
    const courses = await listCourses(account.access_token);
    const subjects = await prisma.subject.findMany({ where: { userId } });
    let syncedAssignments = 0;

    for (const course of courses) {
      await prisma.classroomCourse.upsert({
        where: { userId_classroomId: { userId, classroomId: course.id } },
        update: { name: course.name, section: course.section, lastSyncedAt: new Date() },
        create: {
          userId,
          classroomId: course.id,
          name: course.name,
          section: course.section,
        },
      });

      const [workItems, submissions] = await Promise.all([
        listCourseWork(account.access_token, course.id),
        listSubmissions(account.access_token, course.id),
      ]);
      const submissionsByWorkId = new Map(submissions.map((submission) => [submission.courseWorkId, submission]));
      const linkedSubject = subjects.find((subject) => subject.classroomCourseId === course.id);

      for (const work of workItems) {
        const submission = submissionsByWorkId.get(work.id);
        const classroomKey = `${course.id}:${work.id}`;
        await prisma.assignment.upsert({
          where: { userId_classroomKey: { userId, classroomKey } },
          update: {
            courseName: course.name,
            subjectId: linkedSubject?.id,
            title: work.title,
            details: work.description ?? "",
            dueDate: resolvedDueDate(work),
            alternateLink: work.alternateLink ?? submission?.alternateLink,
            submissionState: submissionState(submission?.state),
            maxPoints: work.maxPoints,
            lastSyncedAt: new Date(),
          },
          create: {
            userId,
            classroomKey,
            courseId: course.id,
            courseName: course.name,
            courseWorkId: work.id,
            subjectId: linkedSubject?.id,
            title: work.title,
            details: work.description ?? "",
            dueDate: resolvedDueDate(work),
            alternateLink: work.alternateLink ?? submission?.alternateLink,
            submissionState: submissionState(submission?.state),
            maxPoints: work.maxPoints,
          },
        });
        syncedAssignments += 1;
      }
    }

    await prisma.user.update({
      where: { id: userId },
      data: {
        lastSyncAt: new Date(),
        lastSyncStatus: `Synced ${courses.length} Classroom courses and ${syncedAssignments} assignments.`,
        lastSyncError: null,
      },
    });
  } catch (error) {
    await prisma.user.update({
      where: { id: userId },
      data: {
        lastSyncError: error instanceof Error ? error.message : "Classroom sync failed.",
        lastSyncStatus: null,
      },
    });
  }

  revalidateApp();
}
