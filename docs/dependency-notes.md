# Dependency Notes

This file tracks dependencies that have known deprecation warnings, cannot be updated to their latest version, or have other issues worth documenting.

## Development Dependencies

| Dependency | Current Version | Latest Version | Note |
|---|---|---|---|
| @cypress/code-coverage | 3.14.7 | 3.14.7 | Uses the deprecated `Cypress.env()` API which triggers a warning in Cypress 15. `Cypress.env()` will be removed in Cypress 16. Migration to `Cypress.expose()` is tracked in [cypress-io/code-coverage#972](https://github.com/cypress-io/code-coverage/pull/972). Cannot set `allowCypressEnv: false` in cypress config until this is resolved. |

## Runtime Dependencies

No issues at this time.
