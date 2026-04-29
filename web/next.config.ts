import type { NextConfig } from "next";
import { copyFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const cspHeader = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-eval' 'unsafe-inline'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: https://*.googleusercontent.com",
  "font-src 'self'",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
  "connect-src 'self' https://classroom.googleapis.com https://oauth2.googleapis.com",
  "upgrade-insecure-requests",
].join("; ");

function mirrorRoutesManifestForVercel() {
  if (process.env.VERCEL !== "1") {
    return;
  }

  const routesManifest = join(process.cwd(), ".next", "routes-manifest.json");
  const deterministicRoutesManifest = join(
    process.cwd(),
    ".next",
    "routes-manifest-deterministic.json",
  );

  const copyManifest = () => {
    if (existsSync(routesManifest) && !existsSync(deterministicRoutesManifest)) {
      copyFileSync(routesManifest, deterministicRoutesManifest);
    }
  };

  copyManifest();

  const interval = setInterval(copyManifest, 100);
  interval.unref();
}

mirrorRoutesManifestForVercel();

const nextConfig: NextConfig = {
  outputFileTracingRoot: process.cwd(),
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Content-Security-Policy", value: cspHeader },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
          { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
        ],
      },
    ];
  },
};

export default nextConfig;
