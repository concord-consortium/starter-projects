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

# --- detect AWS account ID ---
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account: $ACCOUNT_ID"

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
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF
)

# --- create the role ---
echo "Creating IAM role: $REPO_NAME"
aws iam create-role \
  --role-name "$REPO_NAME" \
  --assume-role-policy-document "$TRUST_POLICY" \
  --tags "Key=RepoName,Value=$REPO_NAME" \
  --query 'Role.Arn' --output text

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
