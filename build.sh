#!/usr/bin/env bash

# ============================================================
# MoWang 越狱源索引生成脚本
#
# 功能：
# 1. 保留同一个 Package 的多个历史版本，支持降级
# 2. 支持 iphoneos-arm / iphoneos-arm64 / iphoneos-arm64e
# 3. 生成 Packages
# 4. 生成 Packages.gz / Packages.bz2 / Packages.xz
# 5. 如果安装 zstd，则生成 Packages.zst
# 6. 自动生成 Release
# 7. 自动计算 MD5 / SHA256
# 8. 检查重复 Package + Version + Architecture
#
# 使用：
#   chmod +x build.sh
#   ./build.sh
# ============================================================

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
    echo "❌ 错误：缺少 dpkg-scanpackages"
    echo
    echo "Debian / Ubuntu："
    echo "sudo apt install dpkg-dev"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ 错误：缺少 python3"
    exit 1
fi

if [ ! -d "debs" ]; then
    echo "❌ 错误：找不到 debs/ 目录"
    exit 1
fi

echo
echo "=========================================="
echo "        MoWang 越狱源索引生成器"
echo "=========================================="
echo
echo "源名称：$LABEL"
echo "Origin：$ORIGIN"
echo "描述：$DESCRIPTION"
echo "支持架构：$ARCHITECTURES"
echo

# ============================================================
# 1. 清理旧索引
# ============================================================

echo "=========================================="
echo "[1/6] 清理旧索引"
echo "=========================================="

rm -f Packages
rm -f Packages.gz
rm -f Packages.bz2
rm -f Packages.xz
rm -f Packages.zst

echo "✓ 已清理旧索引"
echo

# ============================================================
# 2. 生成 Packages
#
# -m 非常重要
#
# 它允许同一个 Package 保留多个版本。
#
# 例如：
#
# com.sbcpu.floating
#
# 4.61
# 4.63
# 4.64
# 4.65
# 4.66
# 4.70
#
# 这样才能支持用户降级。
# ============================================================

echo "=========================================="
echo "[2/6] 生成 Packages"
echo "=========================================="

dpkg-scanpackages -m debs > Packages

echo "✓ Packages 生成完成"
echo "  大小：$(wc -c < Packages) bytes"
echo

# ============================================================
# 3. 检查 Packages
# ============================================================

echo "=========================================="
echo "[3/6] 检查 Packages"
echo "=========================================="

python3 <<'PY'
from collections import defaultdict

packages_file = "Packages"

entries = []
current = {}

with open(
    packages_file,
    "r",
    encoding="utf-8",
    errors="replace"
) as f:

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

# ============================================================
# 检查重复 Package + Version + Architecture
# ============================================================

seen = defaultdict(list)

for entry in entries:

    key = (
        entry.get("Package", ""),
        entry.get("Version", ""),
        entry.get("Architecture", ""),
    )

    seen[key].append(
        entry.get("Filename", "")
    )

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
            f"Package={key[0]}"
            f" Version={key[1]}"
            f" Architecture={key[2]}"
        )

        for filename in files:
            print(f"  - {filename}")

    print()
    print(
        "⚠️ 重复包不会阻止索引生成，"
        "但建议检查 debs/ 目录。"
    )

else:

    print(
        "✓ 没有发现完全重复的 "
        "Package + Version + Architecture"
    )

# ============================================================
# 显示架构
# ============================================================

architectures = sorted(
    {
        entry.get("Architecture")
        for entry in entries
        if entry.get("Architecture")
    }
)

print()
print("索引中的实际架构：")

for arch in architectures:
    print(f"  - {arch}")

# ============================================================
# 检查 arm64e
# ============================================================

print()

if "iphoneos-arm64e" in architectures:

    print("✓ 已检测到 iphoneos-arm64e")

else:

    print("⚠️ 当前 Packages 中没有 iphoneos-arm64e 包")
    print("如果你的 debs/ 中没有 arm64e 包，这是正常的。")

PY

echo

# ============================================================
# 4. 生成压缩索引
# ============================================================

echo "=========================================="
echo "[4/6] 生成压缩索引"
echo "=========================================="

gzip -9c Packages > Packages.gz

echo "✓ Packages.gz"

bzip2 -9c Packages > Packages.bz2

echo "✓ Packages.bz2"

xz -9c Packages > Packages.xz

echo "✓ Packages.xz"

if command -v zstd >/dev/null 2>&1; then

    zstd -19 -f Packages -o Packages.zst

    echo "✓ Packages.zst"

else

    echo "ℹ 未安装 zstd，跳过 Packages.zst"

fi

echo

# ============================================================
# 5. 生成 Release
# ============================================================

echo "=========================================="
echo "[5/6] 生成 Release"
echo "=========================================="

python3 - "$ORIGIN" "$LABEL" "$DESCRIPTION" "$ARCHITECTURES" <<'PY'

import hashlib
import os
import sys

origin = sys.argv[1]
label = sys.argv[2]
description = sys.argv[3]
architectures = sys.argv[4]

# ------------------------------------------------------------
# Release 中需要记录的文件
# ------------------------------------------------------------

files = [
    "Packages",
    "Packages.gz",
    "Packages.bz2",
    "Packages.xz",
]

if os.path.isfile("Packages.zst"):
    files.append("Packages.zst")

# ------------------------------------------------------------
# 基础信息
# ------------------------------------------------------------

lines = [
    "Origin: " + origin,
    "Label: " + label,
    "Suite: stable",
    "Version: 1.0",
    "Codename: ios",

    # 注意：
    # 正确字段必须是 Architectures
    # 不能写成 ArchiArchitectures
    "Architectures: " + architectures,

    "Components: main",
    "Description: " + description,
    "",
    "MD5Sum:",
]

# ------------------------------------------------------------
# MD5
# ------------------------------------------------------------

for filename in files:

    with open(filename, "rb") as f:
        data = f.read()

    md5 = hashlib.md5(data).hexdigest()

    lines.append(
        " %s %d %s"
        % (
            md5,
            len(data),
            filename,
        )
    )

# ------------------------------------------------------------
# SHA256
# ------------------------------------------------------------

lines.append("")
lines.append("SHA256:")

for filename in files:

    with open(filename, "rb") as f:
        data = f.read()

    sha256 = hashlib.sha256(data).hexdigest()

    lines.append(
        " %s %d %s"
        % (
            sha256,
            len(data),
            filename,
        )
    )

# ------------------------------------------------------------
# 写入 Release
# ------------------------------------------------------------

with open(
    "Release",
    "w",
    encoding="utf-8"
) as f:

    f.write(
        "\n".join(lines) + "\n"
    )

print("✓ Release 生成完成")

PY

echo

# ============================================================
# 6. 最终检查
# ============================================================

echo "=========================================="
echo "[6/6] 最终检查"
echo "=========================================="

echo
echo "---------- Release ----------"

cat Release

echo
echo "---------- 文件检查 ----------"

for file in \
    Packages \
    Packages.gz \
    Packages.bz2 \
    Packages.xz \
    Release
do

    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "❌ 缺少 $file"
        exit 1
    fi

done

if [ -f Packages.zst ]; then
    echo "✓ Packages.zst"
fi

echo
echo "---------- Architectures 检查 ----------"

if grep -q '^Architectures:' Release; then
    echo "✓ Architectures 字段正确"
else
    echo "❌ Release 缺少 Architectures"
    exit 1
fi

if grep -q '^ArchiArchitectures:' Release; then
    echo "❌ 发现错误字段 ArchiArchitectures"
    exit 1
fi

if grep -q 'iphoneos-arm64e' Release; then
    echo "✓ Release 包含 iphoneos-arm64e"
else
    echo "❌ Release 缺少 iphoneos-arm64e"
    exit 1
fi

echo
echo "=========================================="
echo "        ✓ 软件源索引生成成功"
echo "=========================================="
echo
