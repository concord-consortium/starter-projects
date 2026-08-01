#!/bin/bash
set -euo pipefail

# Configuration — adjust these if your account setup differs
GITHUB_ORG="concord-consortium"
S3_BUCKET="models-resources"
MANAGED_POLICY_NAME="S3-deploy-by-role-tag"

# --- argument handling ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <repo-name>"
  echo "  Creates an IAM role that allows the GitHub repo to deploy to S3."
  echo "  The repo-name must match the S3 folder name in the $S3_BUCKET bucket."
  exit 1
fi

REPO_NAME="$1"

# --- check for required tools ---
command -v aws >/dev/null 2>&1 || { echo "Error: aws CLI not found." >&2; exit 1; }
command -v gh  >/dev/null 2>&1 || {
  echo "Error: gh CLI not found. It is needed to look up the repo's numeric IDs" >&2
  echo "       for the OIDC subject claim. Install it, or see doc/deploy-setup.md" >&2
  echo "       for how to build the trust policy by hand." >&2
  exit 1
}

# --- detect AWS account ID ---
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account: $ACCOUNT_ID"

# --- work out the OIDC subject claim(s) to trust ---
#
# GitHub issues *immutable* subject claims — with the numeric owner and repo IDs
# embedded, delimited by @ — for every repository created or transferred after
# 2026-07-15. Older repositories keep the legacy name-only format unless opted in.
#
#   legacy:    repo:concord-consortium/my-repo:ref:refs/heads/main
#   immutable: repo:concord-consortium@319219/my-repo@1318683401:ref:refs/heads/main
#
# A trust policy matching only one format never matches the other, and the failure
# is misleading: AWS reports "Not authorized to perform sts:AssumeRoleWithWebIdentity",
# which looks like a permissions problem when it is really a string mismatch.
#
# We allow BOTH forms. Each is precisely scoped to this one repository, so the role
# works whichever format GitHub sends, and keeps working if an older repo is later
# opted in to immutable claims.
#
# See: https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/
echo "Looking up numeric IDs for $GITHUB_ORG/$REPO_NAME ..."
if ! REPO_JSON=$(gh api "repos/${GITHUB_ORG}/${REPO_NAME}" --jq '"\(.owner.id) \(.id)"' 2>&1); then
  echo "Error: could not read repos/${GITHUB_ORG}/${REPO_NAME} via gh." >&2
  echo "       Check the repo name, and that you are authenticated (gh auth status)." >&2
  echo "       Details: $REPO_JSON" >&2
  exit 1
fi
OWNER_ID="${REPO_JSON%% *}"
REPO_ID="${REPO_JSON##* }"

case "$OWNER_ID$REPO_ID" in
  *[!0-9]*|"") echo "Error: unexpected owner/repo IDs from GitHub: '$REPO_JSON'" >&2; exit 1 ;;
esac

SUB_LEGACY="repo:${GITHUB_ORG}/${REPO_NAME}:*"
SUB_IMMUTABLE="repo:${GITHUB_ORG}@${OWNER_ID}/${REPO_NAME}@${REPO_ID}:*"
echo "  legacy subject:    $SUB_LEGACY"
echo "  immutable subject: $SUB_IMMUTABLE"

# Report which one GitHub says it will actually send, when that setting is readable.
# It needs more scope than the public repo endpoint, so failure here is not fatal.
if ACTUAL_PREFIX=$(gh api "/repos/${GITHUB_ORG}/${REPO_NAME}/actions/oidc/customization/sub" \
                     --jq '.sub_claim_prefix' 2>/dev/null); then
  echo "  GitHub reports it will send: ${ACTUAL_PREFIX}:..."
fi

# --- build the trust policy ---
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "${SUB_IMMUTABLE}",
            "${SUB_LEGACY}"
          ]
        }
      }
    }
  ]
}
EOF
)

# --- create the role, or update an existing one ---
# Re-running against an existing role updates its trust policy in place. That is
# the migration path for roles created before both subject formats were allowed.
if aws iam get-role --role-name "$REPO_NAME" >/dev/null 2>&1; then
  echo "Role $REPO_NAME already exists — updating its trust policy"
  aws iam update-assume-role-policy \
    --role-name "$REPO_NAME" \
    --policy-document "$TRUST_POLICY"
  echo "arn:aws:iam::${ACCOUNT_ID}:role/${REPO_NAME}"
else
  echo "Creating IAM role: $REPO_NAME"
  aws iam create-role \
    --role-name "$REPO_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --tags "Key=RepoName,Value=$REPO_NAME" \
    --query 'Role.Arn' --output text
fi

# --- attach the shared managed policy ---
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${MANAGED_POLICY_NAME}"
echo "Attaching policy: $POLICY_ARN"
aws iam attach-role-policy \
  --role-name "$REPO_NAME" \
  --policy-arn "$POLICY_ARN"

# --- update workflow files with the role ARN ---
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${REPO_NAME}"

# Only edit workflow files when running inside the target repo. This guards
# against clobbering another repo's workflows (e.g. running this script from
# a starter-projects checkout to create a role for a different repo).
CURRENT_REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
if [ "$CURRENT_REPO" != "$REPO_NAME" ]; then
  echo "Skipping workflow file updates: current repo '$CURRENT_REPO' is not '$REPO_NAME'."
  echo "Add this role ARN to the deploy workflows in $REPO_NAME:"
  echo "  $ROLE_ARN"
else
  UPDATED=0
  for wf in .github/workflows/*.yml .github/workflows/*.yaml; do
    [ -f "$wf" ] || continue
    if grep -q "role-to-assume:" "$wf"; then
      sed -i '' "s|role-to-assume: .*|role-to-assume: ${ROLE_ARN}|" "$wf"
      echo "Updated $wf with role ARN: $ROLE_ARN"
      UPDATED=1
    fi
  done
  if [ "$UPDATED" -eq 0 ]; then
    echo "Warning: no workflow files reference 'role-to-assume:'. Add this role ARN to your workflows:"
    echo "  $ROLE_ARN"
  fi
fi

echo ""
echo "Done."
echo ""
echo "Note: this role grants access to ${S3_BUCKET} only. If your repo also deploys"
echo "somewhere else (e.g. codap-resources), it needs an additional inline policy —"
echo "see doc/deploy-setup.md."
