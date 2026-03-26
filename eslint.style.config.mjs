import typescriptEslint from "typescript-eslint";
import baseConfig from "./eslint.config.mjs";

// style configuration extends default/development configuration
// TODO: document why this is separate from the base config
export default typescriptEslint.config(
  ...baseConfig,
  {
    rules: {
      "@stylistic/array-bracket-spacing": ["error", "never"],
      "@stylistic/object-curly-spacing": ["error", "always"],
      "@stylistic/jsx-curly-spacing": ["error", { "when": "never", "children": { "when": "always" } }],
    }
  }
);
