import { auth } from "@/auth";
import { AuthGate } from "@/components/auth-gate";
import { redirect } from "next/navigation";

export default async function Home() {
  const session = await auth();
  if (!session?.user) return <AuthGate />;
  redirect("/dashboard");
}
