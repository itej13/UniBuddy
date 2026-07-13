type PageResponse<T> = {
  nextPageToken?: string;
} & T;

type CourseResponse = {
  courses?: Array<{ id: string; name: string; section?: string }>;
};

type CourseWorkResponse = {
  courseWork?: Array<{
    id: string;
    title: string;
    description?: string;
    alternateLink?: string;
    dueDate?: { year: number; month: number; day: number };
    dueTime?: { hours?: number; minutes?: number };
    maxPoints?: number;
  }>;
};

type SubmissionsResponse = {
  studentSubmissions?: Array<{
    id: string;
    courseWorkId: string;
    state?: string;
    alternateLink?: string;
  }>;
};

type TokenResponse = {
  access_token?: string;
  expires_in?: number;
  refresh_token?: string;
  scope?: string;
  token_type?: string;
  error?: string;
  error_description?: string;
};

export class ClassroomRequestError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = "ClassroomRequestError";
  }
}

async function classroomRequest<T>(
  accessToken: string,
  path: string,
  query: Record<string, string>,
) {
  const url = new URL(`https://classroom.googleapis.com/v1/${path}`);
  for (const [key, value] of Object.entries(query)) {
    url.searchParams.set(key, value);
  }

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    cache: "no-store",
  });

  if (!response.ok) {
    const body = await response.text();
    throw new ClassroomRequestError(
      response.status,
      `Google Classroom request failed (${response.status}): ${body}`,
    );
  }

  return (await response.json()) as T;
}

export async function refreshGoogleAccessToken(refreshToken: string) {
  const clientId = process.env.AUTH_GOOGLE_ID;
  const clientSecret = process.env.AUTH_GOOGLE_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error("Google OAuth credentials are not configured on the server.");
  }

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: "refresh_token",
      refresh_token: refreshToken,
    }),
    cache: "no-store",
  });
  const result = (await response.json()) as TokenResponse;

  if (!response.ok || !result.access_token) {
    throw new Error(
      `Google could not refresh the Classroom connection: ${result.error_description ?? result.error ?? response.statusText}`,
    );
  }

  return {
    accessToken: result.access_token,
    expiresAt: Math.floor(Date.now() / 1000) + (result.expires_in ?? 3600),
    refreshToken: result.refresh_token,
    scope: result.scope,
    tokenType: result.token_type,
  };
}

async function pagedRequest<TItems, TResponse extends PageResponse<Record<string, unknown>>>(
  accessToken: string,
  path: string,
  query: Record<string, string>,
  itemKey: keyof TResponse,
) {
  const items: TItems[] = [];
  let pageToken: string | undefined;

  do {
    const response = await classroomRequest<TResponse>(accessToken, path, {
      ...query,
      ...(pageToken ? { pageToken } : {}),
    });
    const pageItems = response[itemKey] as TItems[] | undefined;
    items.push(...(pageItems ?? []));
    pageToken = response.nextPageToken;
  } while (pageToken);

  return items;
}

export async function listCourses(accessToken: string) {
  return pagedRequest<
    NonNullable<CourseResponse["courses"]>[number],
    PageResponse<CourseResponse>
  >(
    accessToken,
    "courses",
    { pageSize: "100", courseStates: "ACTIVE" },
    "courses",
  );
}

export async function listCourseWork(accessToken: string, courseId: string) {
  return pagedRequest<
    NonNullable<CourseWorkResponse["courseWork"]>[number],
    PageResponse<CourseWorkResponse>
  >(
    accessToken,
    `courses/${courseId}/courseWork`,
    { pageSize: "100", orderBy: "dueDate desc" },
    "courseWork",
  );
}

export async function listSubmissions(accessToken: string, courseId: string) {
  return pagedRequest<
    NonNullable<SubmissionsResponse["studentSubmissions"]>[number],
    PageResponse<SubmissionsResponse>
  >(
    accessToken,
    `courses/${courseId}/courseWork/-/studentSubmissions`,
    { pageSize: "100", userId: "me" },
    "studentSubmissions",
  );
}

export function resolvedDueDate(work: {
  dueDate?: { year: number; month: number; day: number };
  dueTime?: { hours?: number; minutes?: number };
}) {
  if (!work.dueDate) return null;
  return new Date(
    work.dueDate.year,
    work.dueDate.month - 1,
    work.dueDate.day,
    work.dueTime?.hours ?? 23,
    work.dueTime?.minutes ?? 59,
  );
}

export function submissionState(value?: string) {
  switch (value) {
    case "NEW":
      return "new";
    case "CREATED":
      return "created";
    case "TURNED_IN":
      return "turnedIn";
    case "RETURNED":
      return "returned";
    case "RECLAIMED_BY_STUDENT":
      return "reclaimedByStudent";
    default:
      return "unknown";
  }
}
