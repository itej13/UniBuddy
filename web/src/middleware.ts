import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const session =
    request.cookies.get("authjs.session-token") ??
    request.cookies.get("__Secure-authjs.session-token");

  if (!session) {
    return NextResponse.redirect(new URL("/", request.url));
  }

  return NextResponse.next();
}

export const config = {
  // Use .+ (not .*) so the root path "/" is excluded from the matcher,
  // preventing a redirect loop: / is the unauthenticated landing page.
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/auth).+)"],
};
