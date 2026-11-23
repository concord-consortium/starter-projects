import { defineConfig, devices, type ReporterDescription } from "@playwright/test";
import path from "path";

process.env.REPOSITORY_NAME = process.env.REPOSITORY_NAME || "starter-projects";
process.env.BONJOUR_SERVICE_NAME = process.env.BONJOUR_SERVICE_NAME || process.env.REPOSITORY_NAME;

const reportJson = !!process.env.CI;
const jsonReporter: ReporterDescription = ["json", { outputFile: path.join("test-results", "results.json") }];

export default defineConfig({
  testDir: "./playwright",
  globalSetup: "./playwright/lib/global-setup.ts",
  // Coverage is collected when CODE_COVERAGE is set; see playwright/lib/coverage.ts.
  globalTeardown: "./playwright/lib/global-teardown.ts",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  // GitHub's Linux runner has 4 vCPUs, shared by the dev server and each worker's browser.
  workers: process.env.CI ? 2 : undefined,
  reporter: [
    ["html", { open: "never" }],
    ["list"],
    ...(reportJson ? [jsonReporter] : []),
  ],
  use: {
    baseURL: process.env.CI ? "http://localhost:8080" : undefined,
    trace: process.env.CI ? "on" : "off",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: process.env.CI ? {
    command: "npm start",
    url: "http://localhost:8080/",
    reuseExistingServer: true,
    timeout: 120_000,
  } : undefined,
});
