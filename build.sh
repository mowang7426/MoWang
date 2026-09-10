#!/usr/bin/env bash
# 本地重建软件源索引与 Release
# 用法：把新的 .deb 放进 debs/ 目录，然后在终端运行 ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

# ====== 源信息（按需修改，改完重新运行本脚本）======
ORIGIN="你的名字"
LABEL="我的越狱源"
DESCRIPTION="我的越狱软件源"

if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
  echo "错误：缺少 dpkg-scanpackages，请先安装 dpkg-dev（Debian/Ubuntu: sudo apt install dpkg-dev）" >&2
  exit 1
fi

# 1. 生成包索引
dpkg-scanpackages -m debs > Packages

# 2. 压缩索引（Cydia/Sileo 均可读取 gz/bz2/xz）
gzip -9c Packages > Packages.gz
bzip2 -kf Packages
xz -9c Packages > Packages.xz
if command -v zstd >/dev/null 2>&1; then
  zstd -19 Packages -o Packages.zst
else
  echo "提示：未安装 zstd，跳过 Packages.zst（不影响 Cydia；Sileo 也可读 gz）"
fi

# 3. 重建 Release（含各索引文件的校验和）
python3 - "$ORIGIN" "$LABEL" "$DESCRIPTION" <<'PY'
import hashlib, os, sys
origin, label, description = sys.argv[1], sys.argv[2], sys.argv[3]
names = ['Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz']
if os.path.exists('Packages.zst'):
    names.append('Packages.zst')
lines = [
    'Origin: ' + origin,
    'Label: ' + label,
    'Suite: stable',
    'Version: 1.0',
    'Codename: ios',
    'Architectures: iphoneos-arm iphoneos-arm64',
    'Components: main',
    'Description: ' + description,
    'MD5Sum:',
]
for n in names:
    d = open(n, 'rb').read()
    lines.append(' %s %d %s' % (hashlib.md5(d).hexdigest(), len(d), n))
lines.append('SHA256:')
for n in names:
    d = open(n, 'rb').read()
    lines.append(' %s %d %s' % (hashlib.sha256(d).hexdigest(), len(d), n))
open('Release', 'w').write('\n'.join(lines) + '\n')
print('Release 已更新')
PY

echo "完成：已生成 Packages / Packages.gz / Packages.bz2 / Packages.xz 与 Release"
