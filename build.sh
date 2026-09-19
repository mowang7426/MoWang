#!/usr/bin/env bash

# MoWang 越狱源索引生成脚本
#
# 功能：
# 1. 保留同一个 Package 的多个历史版本，支持降级
# 2. 支持 iphoneos-arm / iphoneos-arm64 / iphoneos-arm64e
# 3. 生成 Packages、Packages.gz、Packages.bz2、Packages.xz
# 4. 可选生成 Packages.zst
# 5. 自动生成正确的 Release
# 6. 自动检查重复的 Package + Version + Architecture
#
# 用法：
#   chmod +x build.sh
#   ./build.sh

set -euo pipefail

cd "$(dirname "$0")"

# ============================================================
# 源信息
# ============================================================

ORIGIN="莫忘"
LABEL="莫忘的专属源"
DESCRIPTION="MoWang 越狱源"

# 支持的架构
ARCHITECTURES="iphoneos-arm iphoneos-arm64 iphoneos-arm64e"

# ============================================================
# 检查依赖
# ============================================================

if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
    echo "错误：缺少 dpkg-scanpackages"
    echo "Debian/Ubuntu：sudo apt install dpkg-dev"
    exit 1
fi

if [ ! -d "debs" ]; then
    echo "错误：找不到 debs/ 目录"
    exit 1
fi

echo "=========================================="
echo "        MoWang 越狱源索引生成器"
echo "=========================================="
echo

echo "源名称：$LABEL"
echo "支持架构：$ARCHITECTURES"
echo

# ============================================================
# 1. 清理旧索引
# ============================================================

echo "[1/6] 清理旧索引..."

rm -f Packages
rm -f Packages.gz
rm -f Packages.bz2
rm -f Packages.xz
rm -f Packages.zst

# ============================================================
# 2. 生成 Packages
#
# 注意：
# -m 必须保留
#
# 因为你的源需要支持：
#
# 4.61
# 4.63
# 4.64
# 4.65
# 4.66
# 4.70
#
# 用户可以正常升级，也可以主动降级。
# ============================================================

echo "[2/6] 生成 Packages..."

dpkg-scanpackages -m debs > Packages

echo "Packages 已生成：$(wc -c < Packages) bytes"

# ============================================================
# 3. 检查 Packages
# ============================================================

echo
echo "[3/6] 检查 Packages..."

python3 <<'PY'
from collections import defaultdict

packages = "Packages"

entries = []

current = {}

with open(packages, "r", encoding="utf-8", errors="replace") as f:
    for line in f:
        line = line.rstrip("\n")

        if line == "":
            if "Package" in current:
                entries.append(current)
            current = {}
            continue

        if ": " in line:
            key, value = line.split(": ", 1)
            current[key] = value

if current and "Package" in current:
    entries.append(current)

print(f"索引包条目：{len(entries)}")

# ------------------------------------------------------------
# 检查重复 Package + Version + Architecture
# ------------------------------------------------------------

seen = defaultdict(list)

for e in entries:
    key = (
        e.get("Package", ""),
        e.get("Version", ""),
        e.get("Architecture", ""),
    )

    seen[key].append(e.get("Filename", ""))

duplicates = {
    key: files
    for key, files in seen.items()
    if len(files) > 1
}

if duplicates:
    print()
    print("⚠️ 发现重复的 Package + Version + Architecture：")

    for key, files in duplicates.items():
        print()
        print(
            f"  Package={key[0]}"
            f" Version={key[1]}"
            f" Architecture={key[2]}"
        )

        for filename in files:
            print(f"    - {filename}")

    print()
    print(
        "这些重复不会阻止索引生成，"
        "但建议检查 debs/ 中是否存在重复包。"
    )
else:
    print("✓ 没有发现完全重复的 Package + Version + Architecture")

# ------------------------------------------------------------
# 显示实际使用到的架构
# ------------------------------------------------------------

architectures = sorted(
    {
        e.get("Architecture")
        for e in entries
        if e.get("Architecture")
    }
)

print()
print("索引中的实际架构：")

for arch in architectures:
    print(f"  - {arch}")

# ------------------------------------------------------------
# 检查是否存在 arm64e
# ------------------------------------------------------------

if "iphoneos-arm64e" not in architectures:
    print()
    print("⚠️ 当前 Packages 中没有 iphoneos-arm64e 包")
    print("如果你的源没有 arm64e 包，这是正常的。")
else:
    print("✓ 已检测到 iphoneos-arm64e")

PY

# ============================================================
# 4. 压缩 Packages
# ============================================================

echo
echo "[4/6] 生成压缩索引..."

gzip -9c Packages > Packages.gz
bzip2 -9c Packages > Packages.bz2
xz -9c Packages > Packages.xz

if command -v zstd >/dev/null 2>&1; then
    zstd -19 -f Packages -o Packages.zst
    echo "✓ Packages.zst"
else
    echo "提示：未安装 zstd，跳过 Packages.zst"
fi

echo "✓ Packages.gz"
echo "✓ Packages.bz2"
echo "✓ Packages.xz"

# ============================================================
# 5. 生成 Release
#
# 注意：
#
# 正确字段是：
#
# Architectures:
#
#
