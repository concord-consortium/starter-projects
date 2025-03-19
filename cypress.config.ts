import { defineConfig } from "cypress";
import codeCoverageTask from "@cypress/code-coverage/task";

export default defineConfig({
  video: false,
  fixturesFolder: false,
  projectId: "r9de4a",
  defaultCommandTimeout: 8000,
  env: {
    coverage: false,
  },
  e2e: {
    setupNodeEvents(on, config) {
      return codeCoverageTask(on, config);
    },
    baseUrl: "http://localhost:8080",
    specPattern: "cypress/e2e/**/*.{js,jsx,ts,tsx}",
  },
});
