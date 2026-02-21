#!/bin/bash
# Copyright (c) 2026 LOVECHEN. All rights reserved.
# 共享下载逻辑：由各 workflow 传入 PRODUCT 和 CHANNEL 参数调用
set -e

PRODUCT="${1:?用法: $0 <product> <channel>}"
CHANNEL="${2:?用法: $0 <product> <channel>}"

chmod +x ./vandyke-dl-linux-amd64

echo "═══════════════════════════════════════════"
echo "  产品: ${PRODUCT} | 渠道: ${CHANNEL}"
echo "═══════════════════════════════════════════"

# 1. dry-run 获取版本号
echo "📋 获取最新版本号…"
OUTPUT=$(./vandyke-dl-linux-amd64 --dry-run --product "$PRODUCT" --channel "$CHANNEL" 2>&1)
VERSION=$(echo "$OUTPUT" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$VERSION" ]; then
    echo "⚠️ 未找到 ${PRODUCT} (${CHANNEL}) 的下载项，跳过"
    echo "$OUTPUT" | tail -5
    exit 0
fi

TAG="v${VERSION}"
echo "✅ 版本: ${VERSION} → Tag: ${TAG}"

# 2. 检查该版本的文件是否已经上传过
echo "🔍 检查 Release ${TAG} 中已有的文件…"
EXISTING_ASSETS=""
if gh release view "$TAG" &>/dev/null; then
    EXISTING_ASSETS=$(gh release view "$TAG" --json assets --jq '.assets[].name' 2>/dev/null || true)
    echo "  已有 $(echo "$EXISTING_ASSETS" | grep -c . || echo 0) 个文件"
else
    echo "  Release ${TAG} 不存在，将创建"
fi

# 3. 检查本次要下载的文件是否都已存在
FILELIST=$(echo "$OUTPUT" | grep -oE '[a-zA-Z0-9._-]+\.(exe|dmg|deb|rpm)' | sort -u)
ALL_EXIST=true
for f in $FILELIST; do
    if ! echo "$EXISTING_ASSETS" | grep -qF "$f"; then
        ALL_EXIST=false
        break
    fi
done

if [ "$ALL_EXIST" = true ] && [ -n "$FILELIST" ]; then
    echo "⏭️ 所有 ${PRODUCT} (${CHANNEL}) 文件已在 Release ${TAG} 中，跳过下载"
    exit 0
fi

# 4. 下载
echo "📥 开始下载 ${PRODUCT} (${CHANNEL})…"
./vandyke-dl-linux-amd64 -o ./downloads --product "$PRODUCT" --channel "$CHANNEL" --workers 2

# 5. 收集文件
FILES=$(find ./downloads -type f | sort)
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')

if [ "$FILE_COUNT" -eq 0 ] || [ -z "$FILES" ]; then
    echo "⚠️ 没有下载到文件，跳过发布"
    exit 0
fi

echo "📦 下载完成: ${FILE_COUNT} 个文件"

# 6. 创建 Release（如果不存在）
if ! gh release view "$TAG" &>/dev/null; then
    echo "🆕 创建 Release ${TAG}…"
    gh release create "$TAG" \
        --title "VanDyke ${TAG}" \
        --notes "## VanDyke ${TAG}

自动检测到新版本，由 GitHub Actions 自动下载并发布。

---
*由 6 个独立 workflow 分别下载上传（SecureCRT/SecureFX/VShell × stable/beta）*"
fi

# 7. 上传文件（跳过已存在的）
echo "📤 上传文件到 Release ${TAG}…"
for f in $FILES; do
    BASENAME=$(basename "$f")
    if echo "$EXISTING_ASSETS" | grep -qF "$BASENAME"; then
        echo "  ⏭️ ${BASENAME} 已存在，跳过"
    else
        echo "  📤 ${BASENAME}…"
        gh release upload "$TAG" "$f" --clobber || echo "  ⚠️ 上传失败: ${BASENAME}"
    fi
done

echo "✅ ${PRODUCT} (${CHANNEL}) 完成！"
