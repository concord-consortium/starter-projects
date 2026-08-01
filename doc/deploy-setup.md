# S3 Deploy Setup

GitHub Actions authenticates with AWS via **OpenID Connect (OIDC)**. GitHub acts as an identity provider and AWS grants a temporary role session — no secrets to rotate or store.

## How it works

GitHub's OIDC provider issues a short-lived token to each workflow run. AWS STS validates this token against the provider thumbprint, checks the `sub` claim (which encodes the repo, branch, etc.), and returns temporary credentials scoped to an IAM role.

## One-time setup (already done)

These only need to be done once per AWS account:

1. **GitHub OIDC identity provider** — registered `token.actions.githubusercontent.com` as an OpenID Connect provider in IAM.
2. **Shared managed policy** — created `S3-deploy-by-role-tag` that grants S3 access to `models-resources/${aws:PrincipalTag/RepoName}/*`, so one policy works for all repo roles.

## Per-repo setup

Requires the **AWS CLI** (with credentials) and the **`gh` CLI** (authenticated). Run the script from this repo (or from `starter-projects`):

```sh
./scripts/create-deploy-role.sh <repo-name>
```

This creates an IAM role named after the repo, tags it with `RepoName`, attaches the shared S3 deploy policy, and scopes the trust policy so only that GitHub repo can assume it. When run from inside the target repo, it also updates every workflow file in `.github/workflows/` that references `role-to-assume` with the new role ARN; when run from a different repo's checkout it skips the file edits and just prints the ARN.

Running it against a repo that **already has a role** is safe: it updates that role's trust policy in place rather than failing. That is the migration path for older roles — see below.

## The OIDC subject claim: two formats

**This is easy to get wrong, and the error message points in the wrong direction.**

GitHub has changed the default format of the `sub` claim. Per [the changelog](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/), **every repository created or transferred after 2026-07-15** uses an *immutable* subject claim with the numeric owner and repo IDs embedded, delimited by `@`. Older repositories keep the legacy name-only format unless they explicitly opt in.

```
legacy:     repo:concord-consortium/my-repo:ref:refs/heads/main
immutable:  repo:concord-consortium@319219/my-repo@1318683401:ref:refs/heads/main
```

A trust policy that matches only one format never matches the other, and the assume-role call fails with:

```
Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

That reads as a *permissions* problem, so the instinct is to widen the IAM policy. That is the wrong fix — the permissions are fine; the subject string simply does not match.

**The script allows both forms**, each precisely scoped to the one repository, so the role works whichever format GitHub sends and keeps working if an older repo is later opted in. You do not need to know which format your repo uses.

### Diagnosing a mismatch

Ask GitHub what it will actually send:

```sh
gh api /repos/concord-consortium/<repo-name>/actions/oidc/customization/sub
```

The `sub_claim_prefix` field is the literal prefix that goes in the token. Compare it against the values in the role's trust policy:

```sh
aws iam get-role --role-name <repo-name> \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition.StringLike'
```

If the prefix matches none of the listed values, that is the bug.

### Migrating an existing role

Roles created before the script allowed both formats carry only the legacy value. They work today, but will break whenever their repo is opted in to immutable claims — and a role created that way for a repo newer than 2026-07-15 never worked at all. To fix, re-run the script:

```sh
./scripts/create-deploy-role.sh <repo-name>
```

It detects the existing role and updates the trust policy in place, leaving the tag and attached policies untouched.

## Deploying somewhere other than models-resources

The shared `S3-deploy-by-role-tag` policy grants access **only** to:

```
arn:aws:s3:::models-resources/${aws:PrincipalTag/RepoName}/*
```

If your repo deploys anywhere else — `codap-resources`, for instance — the role needs an **additional inline policy** for that bucket. Without one, the role is assumed successfully and then the sync fails with `AccessDenied`, which is its own confusing signal.

Two repos already do this. `story-builder` deploys to both buckets and carries an extra inline policy alongside the managed one; `eepsmedia` deploys *only* to `codap-resources` and so skips the managed policy entirely in favour of a single inline one. See [`docs/iam/README.md` in `concord-consortium/eepsmedia`](https://github.com/concord-consortium/eepsmedia/blob/master/docs/iam/README.md) for a worked example including the policy documents.

## Note for repos created from starter-projects

After running the per-repo setup, the `doc/deploy-setup.md` file and `scripts/create-deploy-role.sh` script can be deleted from your repo to avoid having multiple copies that might get out of date. The canonical versions live in `starter-projects`.
