import type { PlaywrightCoverageOptions } from "@bgotink/playwright-coverage";
import { defineConfig, devices, type ReporterDescription } from "@playwright/test";
import path from "path";

const rootDir = __dirname;

process.env.REPOSITORY_NAME = process.env.REPOSITORY_NAME || "starter-projects";
process.env.BONJOUR_SERVICE_NAME = process.env.BONJOUR_SERVICE_NAME || process.env.REPOSITORY_NAME;

const collectCoverage = !!process.env.CI;
const coverageReporter: ReporterDescription = [
  "@bgotink/playwright-coverage",
  {
    sourceRoot: rootDir,
    // This is JavaScript coverage. A stylesheet appears only because the dev build's style-loader
    // module, with hot-reload code no test runs, is mapped onto its lines; no CSS rule is measured.
    // The paths matched here still end in webpack's "?hash", which rewritePath strips later.
    exclude: ["**/*.{scss,css}", "**/*.{scss,css}\\?*"],
    rewritePath: ({absolutePath}: {absolutePath: string}) => {
      return absolutePath
        .replace(`${process.env.REPOSITORY_NAME}/`, "")
        .replace(/\?[0-9a-z]+$/, "");
    },
    resultDir: path.join(rootDir, "test-results", "coverage"),
    reports: [
      ["html"],
      ["lcovonly", { file: "coverage.lcov" }],
      ["text-summary", { file: null }],
    ],
  },
];

const reportJson = !!process.env.CI;
const jsonReporter: ReporterDescription = ["json", { outputFile: path.join("test-results", "results.json") }];

export default defineConfig<PlaywrightCoverageOptions>({
  testDir: "./playwright",
  globalSetup: "./playwright/lib/global-setup.ts",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  // GitHub's Linux runner has 4 vCPUs, shared by the dev server and each worker's browser.
  workers: process.env.CI ? 2 : undefined,
  reporter: [
    ["html", { open: "never" }],
    ["list"],
    ...(collectCoverage ? [coverageReporter] : []),
    ...(reportJson ? [jsonReporter] : []),
  ],
  use: {
    baseURL: process.env.CI ? "http://localhost:8080" : undefined,
    trace: process.env.CI ? "on" : "off",
    collectCoverage,
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
