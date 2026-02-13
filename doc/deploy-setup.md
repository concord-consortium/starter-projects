# S3 Deploy Setup

GitHub Actions authenticates with AWS via **OpenID Connect (OIDC)**. GitHub acts as an identity provider and AWS grants a temporary role session — no secrets to rotate or store.

## How it works

GitHub's OIDC provider issues a short-lived token to each workflow run. AWS STS validates this token against the provider thumbprint, checks the `sub` claim (which encodes the repo, branch, etc.), and returns temporary credentials scoped to an IAM role.

## One-time setup (already done)

These only need to be done once per AWS account:

1. **GitHub OIDC identity provider** — registered `token.actions.githubusercontent.com` as an OpenID Connect provider in IAM.
2. **Shared managed policy** — created `S3-deploy-by-role-tag` that grants S3 access to `models-resources/${aws:PrincipalTag/RepoName}/*`, so one policy works for all repo roles.

## Per-repo setup

Run the script from this repo (or from `starter-projects`):

```sh
./scripts/create-deploy-role.sh <repo-name>
```

This creates an IAM role named after the repo, tags it with `RepoName`, attaches the shared S3 deploy policy, scopes the trust policy so only that GitHub repo can assume it, and updates `.github/workflows/ci.yml` with the role ARN.

## Note for repos created from starter-projects

After running the per-repo setup, the `doc/deploy-setup.md` file and `scripts/create-deploy-role.sh` script can be deleted from your repo to avoid having multiple copies that might get out of date. The canonical versions live in `starter-projects`.
