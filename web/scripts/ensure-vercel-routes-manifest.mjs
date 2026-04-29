import { copyFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const nextDir = join(process.cwd(), ".next");
const routesManifest = join(nextDir, "routes-manifest.json");
const deterministicRoutesManifest = join(nextDir, "routes-manifest-deterministic.json");

if (!existsSync(routesManifest)) {
  throw new Error("Next.js did not emit .next/routes-manifest.json");
}

if (!existsSync(deterministicRoutesManifest)) {
  copyFileSync(routesManifest, deterministicRoutesManifest);
  console.log("Created .next/routes-manifest-deterministic.json for Vercel deployment packaging.");
}
