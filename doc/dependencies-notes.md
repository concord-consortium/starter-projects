# Dependency Upgrade Notes

## eslint 9 → 10 (blocked as of 2026-03-25)

ESLint 10.0.0 was released 2026-02-06. Cannot upgrade yet because key
plugins don't support it:
- `typescript-eslint` (latest 8.57.2) requires eslint <10
- `eslint-plugin-import` supports up to eslint ^9
- `eslint-plugin-react` supports up to eslint ^9
- `eslint-webpack-plugin` supports up to eslint ^9

Revisit once `typescript-eslint` releases a version with eslint 10 support.

## typescript 5 → 6 (blocked as of 2026-03-25)

TypeScript 6.0.2 (first stable release) came out 2026-03-23. It is a
transitional release aligning the JavaScript-based compiler with the new
native Go-based compiler ("tsgo"). The release focuses on compatibility
between the two compilers rather than new language features.

Blocked by peer dependencies — the ecosystem hasn't caught up yet:
- `@typescript-eslint/parser` requires typescript <6.0.0
- `@typescript-eslint/eslint-plugin` requires typescript <6.0.0
- `typescript-eslint` requires typescript <6.0.0
- `ts-jest` requires typescript <6

This is tied to the eslint ecosystem upgrade above. Revisit together.
