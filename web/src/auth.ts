import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import { customFetch } from "next-auth";
import { PrismaAdapter } from "@auth/prisma-adapter";
import { prisma } from "@/lib/prisma";

export const classroomScopes = [
  "openid",
  "email",
  "profile",
  "https://www.googleapis.com/auth/classroom.courses.readonly",
  "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
].join(" ");

// Google's OIDC discovery doc advertises authorization_response_iss_parameter_supported: true
// but Google never includes `iss` in the actual authorization response. oauth4webapi enforces
// the flag strictly, so we strip it from the discovery response before it's processed.
async function googleFetch(...args: Parameters<typeof fetch>) {
  const url = new URL(args[0] instanceof Request ? args[0].url : String(args[0]));
  if (url.pathname.endsWith("/.well-known/openid-configuration")) {
    const res = await fetch(...args);
    const data: Record<string, unknown> = await res.json();
    delete data.authorization_response_iss_parameter_supported;
    return Response.json(data);
  }
  return fetch(...args);
}

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: PrismaAdapter(prisma),
  session: { strategy: "database" },
  trustHost: true,
  providers: [
    Google({
      authorization: {
        params: {
          access_type: "offline",
          prompt: "consent",
          scope: classroomScopes,
        },
      },
      [customFetch]: googleFetch,
    }),
  ],
  callbacks: {
    session({ session, user }) {
      if (session.user) {
        session.user.id = user.id;
      }
      return session;
    },
  },
});
