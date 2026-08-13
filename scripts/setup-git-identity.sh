#!/bin/sh
# Cấu hình workspace này (chỉ local .git/config, KHÔNG đụng global) để mọi commit/push
# luôn dùng account phucmouse135 (Nguyễn Đình Phúc), tách biệt với account default máy.
# Chạy lại script này bất cứ khi nào .git/config bị reset hoặc clone repo mới.
set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

ACCOUNT_NAME="Nguyễn Đình Phúc"
ACCOUNT_EMAIL="102985779+phucmouse135@users.noreply.github.com"
WRAPPER="/c/Users/NguyenDinhPhuc/.gh-configs/do-an-account2/git-credential-wrapper.sh"

git config --local user.name "$ACCOUNT_NAME"
git config --local user.email "$ACCOUNT_EMAIL"

# Reset chain (bỏ credential.helper kế thừa từ global, vd. account default máy),
# rồi set đúng 1 helper trỏ về account phucmouse135.
git config --local --unset-all credential.helper 2>/dev/null || true
git config --local credential.helper ""
git config --local --add credential.helper "!'$WRAPPER'"

git config --local core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/commit-msg .githooks/pre-push scripts/setup-git-identity.sh 2>/dev/null || true

echo "Đã cấu hình workspace '$REPO_ROOT' dùng account: $ACCOUNT_NAME <$ACCOUNT_EMAIL>"
echo "  - user.name/user.email: local (không đụng global)"
echo "  - credential.helper: local, trỏ về $WRAPPER"
echo "  - core.hooksPath: .githooks (pre-commit + commit-msg + pre-push gate)"
