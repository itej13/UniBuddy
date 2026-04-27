import { BookOpenCheck } from "lucide-react";
import { signInWithGoogle } from "@/lib/actions";

export function AuthGate() {
  return (
    <main className="grid min-h-screen place-items-center px-6 py-10">
      <section className="w-full max-w-md rounded-lg border border-stone-200 bg-white p-6 shadow-sm">
        <div className="mb-6 flex items-center gap-3">
          <div className="grid size-11 place-items-center rounded-lg bg-blue-600 text-white">
            <BookOpenCheck size={22} />
          </div>
          <div>
            <h1 className="text-xl font-semibold text-stone-950">UniBuddy</h1>
            <p className="text-sm text-stone-500">Your college command center.</p>
          </div>
        </div>
        <p className="mb-6 text-sm leading-6 text-stone-600">
          Sign in with your Google account to sync Classroom courses and keep attendance,
          timetable, and submissions in one persisted web workspace.
        </p>
        <form action={signInWithGoogle}>
          <button className="h-11 w-full rounded-md bg-stone-950 px-4 text-sm font-semibold text-white transition hover:bg-stone-800">
            Sign in with Google
          </button>
        </form>
        <p className="mt-4 text-xs leading-5 text-stone-500">
          Configure Google web OAuth credentials in <code>web/.env.local</code> before signing in.
        </p>
      </section>
    </main>
  );
}
