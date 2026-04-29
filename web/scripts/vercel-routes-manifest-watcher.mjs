import { copyFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptPath = fileURLToPath(import.meta.url);
const nextDir = join(process.cwd(), ".next");
const routesManifest = join(nextDir, "routes-manifest.json");
const deterministicRoutesManifest = join(nextDir, "routes-manifest-deterministic.json");

if (process.argv.includes("--watch")) {
  const startedAt = Date.now();

  const interval = setInterval(() => {
    if (existsSync(routesManifest) && !existsSync(deterministicRoutesManifest)) {
      copyFileSync(routesManifest, deterministicRoutesManifest);
    }

    if (Date.now() - startedAt > 120_000) {
      clearInterval(interval);
      process.exit(0);
    }
  }, 50);
} else {
  const child = spawn(process.execPath, [scriptPath, "--watch"], {
    cwd: process.cwd(),
    detached: true,
    env: process.env,
    stdio: "ignore",
  });

  child.unref();
}
