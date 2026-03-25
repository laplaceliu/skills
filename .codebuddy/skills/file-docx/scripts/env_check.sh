#!/usr/bin/env bash
# minimax-docx 快速环境检查
# 跨平台：macOS、Linux、WSL、Git Bash
# 在任何 minimax-docx 操作之前运行此脚本。初始安装使用 setup.sh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTNET_DIR="$SCRIPT_DIR/dotnet"

# 强制 dotnet CLI 输出英文
export DOTNET_CLI_UI_LANGUAGE=en

echo "=== minimax-docx 环境检查 ==="
echo ""

STATUS="就绪"
WARNINGS=0

# --- 检测平台 ---
OS="未知"
case "$(uname -s)" in
    Darwin)  OS="macos" ;;
    Linux)
        OS="linux"
        grep -qi microsoft /proc/version 2>/dev/null && OS="wsl"
        ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows-shell" ;;
esac

# --- 关键：.NET SDK ---
if ! command -v dotnet &>/dev/null; then
    printf "[失败]    %-14s 未找到\n" "dotnet"
    echo ""
    echo "  .NET SDK 是必需的。安装方法："
    case "$OS" in
        macos)   echo "    brew install --cask dotnet-sdk" ;;
        linux|wsl)
            echo "    # 选项 1：Microsoft 安装脚本"
            echo "    wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh"
            echo "    chmod +x /tmp/dotnet-install.sh && /tmp/dotnet-install.sh --channel 8.0"
            echo "    # 选项 2 (Ubuntu/Debian)：sudo apt-get install -y dotnet-sdk-8.0"
            ;;
        windows-shell) echo "    winget install Microsoft.DotNet.SDK.8" ;;
        *) echo "    https://dotnet.microsoft.com/download" ;;
    esac
    echo ""
    echo "  或运行完整安装：bash scripts/setup.sh"
    echo ""
    STATUS="未就绪"
else
    local_ver=$(dotnet --version 2>/dev/null || echo "0.0.0")
    local_major="${local_ver%%.*}"
    if [ "$local_major" -ge 8 ] 2>/dev/null; then
        printf "[正常]    %-14s %s (>= 8.0)\n" "dotnet" "$local_ver"
    else
        printf "[失败]    %-14s %s (需要 >= 8.0)\n" "dotnet" "$local_ver"
        STATUS="未就绪"
    fi
fi

# --- 关键：NuGet 包 ---
if [ -d "$DOTNET_DIR" ]; then
    if [ -f "$DOTNET_DIR/MiniMaxAIDocx.Cli/bin/Debug/net10.0/MiniMaxAIDocx.Cli.dll" ] || \
       [ -f "$DOTNET_DIR/MiniMaxAIDocx.Cli/bin/Debug/net8.0/MiniMaxAIDocx.Cli.dll" ]; then
        printf "[正常]    %-14s 已构建\n" "项目"
    else
        # 尝试还原 + 构建
        if dotnet restore "$DOTNET_DIR" --verbosity quiet &>/dev/null; then
            printf "[正常]    %-14s 包已还原\n" "nuget"
            if dotnet build "$DOTNET_DIR" --verbosity quiet --no-restore &>/dev/null; then
                printf "[正常]    %-14s 构建成功\n" "项目"
            else
                printf "[失败]    %-14s 构建失败（运行：dotnet build %s）\n" "项目" "$DOTNET_DIR"
                STATUS="未就绪"
            fi
        else
            printf "[失败]    %-14s 还原失败\n" "nuget"
            echo ""
            echo "  常见原因："
            echo "    - 无网络访问（NuGet 需要下载包）"
            echo "    - 企业代理阻止 nuget.org"
            echo "    - SSL 证书问题（尝试：dotnet nuget list source）"
            echo ""
            STATUS="未就绪"
        fi
    fi
else
    printf "[失败]    %-14s 目录未找到：%s\n" "项目" "$DOTNET_DIR"
    STATUS="未就绪"
fi

# --- 可选：pandoc ---
if command -v pandoc &>/dev/null; then
    pandoc_ver=$(pandoc --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "?")
    printf "[正常]    %-14s %s（内容预览）\n" "pandoc" "$pandoc_ver"
else
    printf "[警告]    %-14s 未找到 — docx_preview.sh 将使用回退\n" "pandoc"
    WARNINGS=$((WARNINGS + 1))
    case "$OS" in
        macos)        echo "           安装：brew install pandoc" ;;
        linux|wsl)    echo "           安装：sudo apt-get install pandoc  # 或 dnf/pacman" ;;
        windows-shell) echo "           安装：winget install JohnMacFarlane.Pandoc" ;;
    esac
fi

# --- 可选：LibreOffice ---
if command -v soffice &>/dev/null; then
    soffice_ver=$(soffice --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "?")
    printf "[正常]    %-14s %s（.doc 转换）\n" "soffice" "$soffice_ver"
else
    # 检查常见路径
    soffice_found=false
    for p in \
        "/Applications/LibreOffice.app/Contents/MacOS/soffice" \
        "/usr/lib/libreoffice/program/soffice" \
        "/snap/bin/libreoffice" \
        "/opt/libreoffice/program/soffice"; do
        if [ -x "$p" ]; then
            printf "[正常]    %-14s 在 %s 找到（.doc 转换）\n" "soffice" "$p"
            soffice_found=true
            break
        fi
    done
    if ! $soffice_found; then
        printf "[警告]    %-14s 未找到 — 无法转换 .doc 文件\n" "soffice"
        WARNINGS=$((WARNINGS + 1))
        case "$OS" in
            macos)        echo "           安装：brew install --cask libreoffice" ;;
            linux|wsl)    echo "           安装：sudo apt-get install libreoffice-core" ;;
            windows-shell) echo "           安装：winget install TheDocumentFoundation.LibreOffice" ;;
        esac
    fi
fi

# --- 可选：zip/unzip ---
zip_ok=true
if ! command -v zip &>/dev/null; then
    printf "[警告]    %-14s 未找到（可选，.NET 原生处理 DOCX）\n" "zip"
    zip_ok=false
    WARNINGS=$((WARNINGS + 1))
fi
if ! command -v unzip &>/dev/null; then
    printf "[警告]    %-14s 未找到（可选，.NET 原生处理 DOCX）\n" "unzip"
    zip_ok=false
    WARNINGS=$((WARNINGS + 1))
fi
if $zip_ok; then
    printf "[正常]    %-14s 可用\n" "zip/unzip"
fi

# --- 编码检查 ---
current_lang="${LANG:-}"
if [ -n "$current_lang" ] && echo "$current_lang" | grep -qi "utf-8\|utf8"; then
    printf "[正常]    %-14s %s\n" "locale" "$current_lang"
else
    if [ -z "$current_lang" ]; then
        printf "[警告]    %-14s LANG 未设置（CJK 文本可能有问题）\n" "locale"
    else
        printf "[警告]    %-14s %s（非 UTF-8，CJK 文本可能有问题）\n" "locale" "$current_lang"
    fi
    WARNINGS=$((WARNINGS + 1))
    echo "           修复：export LANG=en_US.UTF-8"
fi

# --- Shell 脚本权限 ---
perm_issues=0
for s in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$s" ] && [ ! -x "$s" ]; then
        perm_issues=$((perm_issues + 1))
    fi
done
if [ "$perm_issues" -gt 0 ]; then
    printf "[警告]    %-14s %d 个脚本不可执行\n" "权限" "$perm_issues"
    echo "           修复：chmod +x scripts/*.sh"
    WARNINGS=$((WARNINGS + 1))
else
    printf "[正常]    %-14s 所有脚本可执行\n" "权限"
fi

# --- 结果 ---
echo ""
if [ "$STATUS" = "就绪" ]; then
    if [ "$WARNINGS" -gt 0 ]; then
        echo "状态：就绪（有 $WARNINGS 个警告 — 可选功能可能受限）"
    else
        echo "状态：就绪"
    fi
else
    echo "状态：未就绪"
    echo ""
    echo "关键依赖项缺失。运行完整安装："
    echo "  bash scripts/setup.sh          # macOS / Linux / WSL"
    echo "  powershell scripts/setup.ps1   # Windows PowerShell"
    exit 1
fi
