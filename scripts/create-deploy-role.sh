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

# --- update ci.yml with the role ARN ---
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${REPO_NAME}"
CI_YML=".github/workflows/ci.yml"
if [ -f "$CI_YML" ]; then
  sed -i '' "s|role-to-assume: .*|role-to-assume: ${ROLE_ARN}|" "$CI_YML"
  echo "Updated $CI_YML with role ARN: $ROLE_ARN"
else
  echo "Warning: $CI_YML not found. Add this role ARN to your workflow:"
  echo "  $ROLE_ARN"
fi

echo ""
echo "Done."
