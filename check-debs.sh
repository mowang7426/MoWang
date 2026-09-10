#!/usr/bin/env bash
# 检查 debs/ 目录里所有 .deb 是否都能被正常解析
# 用法：./check-debs.sh   （有坏包时返回非 0 并列出文件名）
set -uo pipefail
cd "$(dirname "$0")"
broken=0
for f in debs/*.deb; do
  [ -e "$f" ] || continue
  if ! dpkg-deb -I "$f" >/dev/null 2>&1; then
    echo "[坏包] $f"
    broken=1
  fi
done
if [ "$broken" -eq 0 ]; then
  echo "全部 $(ls debs/*.deb 2>/dev/null | wc -l | tr -d ' ') 个 deb 均可正常解析 ✔"
else
  echo "存在坏包：请重新打包后再上传，否则 GitHub Actions 构建会失败。"
fi
exit $broken
