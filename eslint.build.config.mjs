import { defineConfig } from "eslint/config";
import baseConfig from "./eslint.config.mjs";

// build/production configuration extends default/development configuration
export default defineConfig(
  ...baseConfig,
  {
    files: ["**/*.{js,mjs,ts,tsx,jsx}"],
    rules: {
      "@eslint-community/eslint-comments/no-unused-disable": "warn",
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "no-debugger": "error"
    }
  }
);
