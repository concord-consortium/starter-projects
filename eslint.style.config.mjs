import { defineConfig } from "eslint/config";
import baseConfig from "./eslint.config.mjs";

// style configuration extends default/development configuration
// TODO: document why this is separate from the base config
export default defineConfig(
  ...baseConfig,
  {
    rules: {
      "@stylistic/array-bracket-spacing": ["error", "never"],
      "@stylistic/object-curly-spacing": ["error", "always"],
      "@stylistic/jsx-curly-spacing": ["error", { "when": "never", "children": { "when": "always" } }],
    }
  }
);
