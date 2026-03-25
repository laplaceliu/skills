#!/usr/bin/env bash
# minimax-docx 环境设置与初始化脚本
# 支持：macOS (Homebrew)、Linux (apt/dnf/pacman)、WSL
# 许可证：MIT
set -euo pipefail

# 强制 dotnet CLI 输出英文
export DOTNET_CLI_UI_LANGUAGE=en

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTNET_DIR="$SCRIPT_DIR/dotnet"
LOG_FILE="$PROJECT_DIR/.setup.log"

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[正常]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[警告]${NC}  $*"; }
fail()  { echo -e "${RED}[失败]${NC}  $*"; }
info()  { echo -e "${BLUE}[信息]${NC}  $*"; }
step()  { echo -e "\n${BLUE}=== $* ===${NC}"; }

# --- 检测操作系统和包管理器 ---
detect_platform() {
    OS="未知"
    PKG_MGR="未知"
    ARCH="$(uname -m)"

    case "$(uname -s)" in
        Darwin)
            OS="macos"
            if command -v brew &>/dev/null; then
                PKG_MGR="brew"
            else
                PKG_MGR="none"
            fi
            ;;
        Linux)
            OS="linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian|linuxmint|pop)
                        PKG_MGR="apt"
                        ;;
                    fedora|rhel|centos|rocky|alma)
                        PKG_MGR="dnf"
                        ;;
                    arch|manjaro|endeavouros)
                        PKG_MGR="pacman"
                        ;;
                    opensuse*|sles)
                        PKG_MGR="zypper"
                        ;;
                    alpine)
                        PKG_MGR="apk"
                        ;;
                    *)
                        PKG_MGR="未知"
                        ;;
                esac
            fi
            # 检测 WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="wsl"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows-git-bash"
            PKG_MGR="none"
            ;;
    esac

    echo "平台：$OS ($ARCH)，包管理器：$PKG_MGR"
}

# --- .NET SDK 安装 ---
install_dotnet() {
    step "检查 .NET SDK"

    if command -v dotnet &>/dev/null; then
        local ver
        ver=$(dotnet --version 2>/dev/null || echo "0")
        local major="${ver%%.*}"
        if [ "$major" -ge 8 ] 2>/dev/null; then
            log "dotnet $ver 已安装 (>= 8.0 正常)"
            return 0
        else
            warn "找到 dotnet $ver 但 < 8.0，正在升级..."
        fi
    fi

    info "正在安装 .NET SDK..."
    case "$PKG_MGR" in
        brew)
            brew install --cask dotnet-sdk
            ;;
        apt)
            # 为 Ubuntu/Debian 添加 Microsoft 包仓库
            if ! dpkg -l dotnet-sdk-8.0 &>/dev/null 2>&1; then
                info "添加 Microsoft 包仓库..."
                sudo apt-get update -qq
                sudo apt-get install -y -qq wget apt-transport-https
                wget -q "https://dot.net/v1/dotnet-install.sh" -O /tmp/dotnet-install.sh
                chmod +x /tmp/dotnet-install.sh
                /tmp/dotnet-install.sh --channel 8.0 --install-dir "$HOME/.dotnet"
                export PATH="$HOME/.dotnet:$PATH"
                echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.bashrc"
            fi
            ;;
        dnf)
            sudo dnf install -y dotnet-sdk-8.0
            ;;
        pacman)
            sudo pacman -S --noconfirm dotnet-sdk
            ;;
        zypper)
            sudo zypper install -y dotnet-sdk-8.0
            ;;
        apk)
            apk add --no-cache dotnet8-sdk
            ;;
        none)
            if [ "$OS" = "windows-git-bash" ]; then
                fail "在 Windows 上，从此安装 .NET SDK：https://dotnet.microsoft.com/download"
                fail "然后重启终端并重新运行此脚本。"
                return 1
            fi
            # 回退：使用 Microsoft 安装脚本
            info "使用 Microsoft 安装脚本..."
            wget -q "https://dot.net/v1/dotnet-install.sh" -O /tmp/dotnet-install.sh || \
                curl -sSL "https://dot.net/v1/dotnet-install.sh" -o /tmp/dotnet-install.sh
            chmod +x /tmp/dotnet-install.sh
            /tmp/dotnet-install.sh --channel 8.0 --install-dir "$HOME/.dotnet"
            export PATH="$HOME/.dotnet:$PATH"
            echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.bashrc"
            ;;
        *)
            warn "未知包管理器。手动安装 .NET SDK：https://dotnet.microsoft.com/download"
            return 1
            ;;
    esac

    # 验证
    if command -v dotnet &>/dev/null; then
        log "dotnet $(dotnet --version) 已安装"
    else
        fail "dotnet 安装失败。手动安装：https://dotnet.microsoft.com/download"
        return 1
    fi
}

# --- Pandoc 安装（可选） ---
install_pandoc() {
    step "检查 pandoc（可选：内容预览）"

    if command -v pandoc &>/dev/null; then
        log "pandoc $(pandoc --version | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?') 已安装"
        return 0
    fi

    info "正在安装 pandoc..."
    case "$PKG_MGR" in
        brew)   brew install pandoc ;;
        apt)    sudo apt-get install -y -qq pandoc ;;
        dnf)    sudo dnf install -y pandoc ;;
        pacman) sudo pacman -S --noconfirm pandoc ;;
        zypper) sudo zypper install -y pandoc ;;
        apk)    apk add --no-cache pandoc ;;
        *)
            warn "无法自动安装 pandoc。手动安装：https://pandoc.org/installing.html"
            return 0
            ;;
    esac

    if command -v pandoc &>/dev/null; then
        log "pandoc 已安装"
    else
        warn "pandoc 安装失败（可选，将优雅降级）"
    fi
}

# --- LibreOffice 安装（可选） ---
install_soffice() {
    step "检查 LibreOffice/soffice（可选：.doc 转换）"

    if command -v soffice &>/dev/null; then
        log "soffice 已安装"
        return 0
    fi

    # 同时检查常见安装路径
    local soffice_paths=(
        "/usr/bin/soffice"
        "/usr/local/bin/soffice"
        "/opt/libreoffice/program/soffice"
        "/snap/bin/libreoffice"
        "/Applications/LibreOffice.app/Contents/MacOS/soffice"
    )
    for p in "${soffice_paths[@]}"; do
        if [ -x "$p" ]; then
            log "在 $p 找到 soffice"
            if [ "$OS" = "macos" ] && [ "$p" = "/Applications/LibreOffice.app/Contents/MacOS/soffice" ]; then
                info "提示：添加到 PATH：ln -s '$p' /usr/local/bin/soffice"
            fi
            return 0
        fi
    done

    info "正在安装 LibreOffice（这可能需要一段时间）..."
    case "$PKG_MGR" in
        brew)   brew install --cask libreoffice ;;
        apt)    sudo apt-get install -y -qq libreoffice-core ;;
        dnf)    sudo dnf install -y libreoffice-core ;;
        pacman) sudo pacman -S --noconfirm libreoffice-still ;;
        zypper) sudo zypper install -y libreoffice ;;
        apk)    apk add --no-cache libreoffice ;;
        *)
            warn "无法自动安装 LibreOffice。手动安装：https://www.libreoffice.org/download/"
            return 0
            ;;
    esac

    if command -v soffice &>/dev/null; then
        log "soffice 已安装"
    else
        warn "安装后未找到 soffice（可选，.doc 转换不可用）"
    fi
}

# --- zip/unzip ---
install_zip_tools() {
    step "检查 zip/unzip"

    local need_zip=false need_unzip=false
    command -v zip &>/dev/null   && log "zip 已安装"   || need_zip=true
    command -v unzip &>/dev/null && log "unzip 已安装" || need_unzip=true

    if ! $need_zip && ! $need_unzip; then
        return 0
    fi

    info "正在安装 zip/unzip..."
    case "$PKG_MGR" in
        brew)   brew install zip unzip 2>/dev/null || true ;;
        apt)    sudo apt-get install -y -qq zip unzip ;;
        dnf)    sudo dnf install -y zip unzip ;;
        pacman) sudo pacman -S --noconfirm zip unzip ;;
        zypper) sudo zypper install -y zip unzip ;;
        apk)    apk add --no-cache zip unzip ;;
        *)      warn "手动安装 zip/unzip（可选，.NET 原生处理 DOCX）" ;;
    esac
}

# --- .NET 项目构建 ---
build_project() {
    step "构建 minimax-docx .NET 项目"

    if [ ! -d "$DOTNET_DIR" ]; then
        fail "Dotnet 项目目录未找到：$DOTNET_DIR"
        return 1
    fi

    cd "$DOTNET_DIR"

    info "还原 NuGet 包..."
    if ! dotnet restore --verbosity quiet 2>>"$LOG_FILE"; then
        fail "NuGet 还原失败。检查网络和 $LOG_FILE 了解详情。"
        fail "常见原因："
        fail "  - 无网络访问（NuGet 需要下载包）"
        fail "  - 企业代理阻止 nuget.org"
        fail "  - 磁盘空间不足"
        echo ""
        fail "手动尝试：cd $DOTNET_DIR && dotnet restore --verbosity detailed"
        return 1
    fi
    log "NuGet 包已还原"

    info "正在构建项目..."
    if ! dotnet build --verbosity quiet --no-restore 2>>"$LOG_FILE"; then
        fail "构建失败。检查 $LOG_FILE 了解详情。"
        fail "手动尝试：cd $DOTNET_DIR && dotnet build --verbosity normal"
        return 1
    fi
    log "项目构建成功"

    cd "$PROJECT_DIR"
}

# --- Shell 脚本权限 ---
fix_permissions() {
    step "设置脚本权限"

    local scripts=(
        "$SCRIPT_DIR/env_check.sh"
        "$SCRIPT_DIR/docx_preview.sh"
        "$SCRIPT_DIR/doc_to_docx.sh"
        "$SCRIPT_DIR/setup.sh"
    )

    for s in "${scripts[@]}"; do
        if [ -f "$s" ]; then
            chmod +x "$s"
            log "chmod +x $(basename "$s")"
        fi
    done
}

# --- NuGet 代理/证书问题（企业环境） ---
check_nuget_config() {
    step "检查 NuGet 配置"

    local nuget_config="$HOME/.nuget/NuGet/NuGet.Config"
    if [ -f "$nuget_config" ]; then
        log "NuGet 配置存在：$nuget_config"
    else
        info "未找到自定义 NuGet 配置（使用默认值）"
    fi

    # 测试 NuGet 连接
    if dotnet nuget list source 2>/dev/null | grep -q "nuget.org"; then
        log "nuget.org 源已配置"
    else
        warn "nuget.org 不在源中。正在添加..."
        dotnet nuget add source "https://api.nuget.org/v3/index.json" --name "nuget.org" 2>/dev/null || true
    fi
}

# --- 区域设置/编码检查 ---
check_locale() {
    step "检查区域设置和编码"

    local current_lang="${LANG:-未设置}"
    local current_lc="${LC_ALL:-未设置}"

    if echo "$current_lang" | grep -qi "utf-8\|utf8"; then
        log "区域设置支持 UTF-8：LANG=$current_lang"
    else
        warn "区域设置可能不支持 UTF-8：LANG=$current_lang"
        warn "CJK 文档处理需要 UTF-8。设置：export LANG=en_US.UTF-8"
        if [ "$OS" = "linux" ] || [ "$OS" = "wsl" ]; then
            info "永久修复：sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8"
        fi
    fi
}

# --- 字体检查（用于 CJK 和专业文档） ---
check_fonts() {
    step "检查文档渲染字体"

    if [ "$OS" = "macos" ]; then
        # macOS 内置良好的 CJK 支持
        log "macOS：内置 CJK 字体支持（苹方、Hiragino、Apple SD Gothic）"
        log "macOS：内置西文字体（Helvetica、Times、通过 Office 的 Calibri）"
        if [ -d "/Applications/Microsoft Word.app" ] || [ -d "/Applications/Microsoft Office" ]; then
            log "Microsoft Office 字体可用（Calibri、Cambria 等）"
        else
            warn "未安装 Microsoft Office — 本机可能缺少 Calibri/Cambria 字体"
            info "文档将使用回退字体在此机器上渲染"
            info "安装了 Office 的收件人将看到正确的字体"
        fi
    elif [ "$OS" = "linux" ] || [ "$OS" = "wsl" ]; then
        # 检查关键字体包
        local missing_fonts=()

        if ! fc-list 2>/dev/null | grep -qi "liberation\|times new roman\|calibri"; then
            missing_fonts+=("西文：liberation-fonts 或 msttcorefonts")
        fi

        if ! fc-list 2>/dev/null | grep -qi "noto.*cjk\|wqy\|simsun\|pingfang"; then
            missing_fonts+=("CJK：noto-fonts-cjk 或 wqy-microhei")
        fi

        if [ ${#missing_fonts[@]} -eq 0 ]; then
            log "字体支持看起来良好"
        else
            warn "缺少字体可能影响文档渲染："
            for f in "${missing_fonts[@]}"; do
                warn "  - $f"
            done
            info "安装字体："
            case "$PKG_MGR" in
                apt)
                    info "  sudo apt-get install -y fonts-liberation fonts-noto-cjk"
                    info "  # 对于 MS 核心字体：sudo apt-get install -y ttf-mscorefonts-installer"
                    ;;
                dnf)
                    info "  sudo dnf install -y liberation-fonts google-noto-sans-cjk-fonts"
                    ;;
                pacman)
                    info "  sudo pacman -S ttf-liberation noto-fonts-cjk"
                    ;;
                *)
                    info "  为您的发行版安装 Liberation Fonts 和 Noto CJK 字体"
                    ;;
            esac
        fi
    fi
}

# --- 验证运行 ---
verify_installation() {
    step "验证测试"

    local test_output="/tmp/minimax-docx-setup-test-$$.docx"

    info "正在创建测试文档..."
    if cd "$DOTNET_DIR" && dotnet run --project MiniMaxAIDocx.Cli -- create \
        --type report --output "$test_output" --title "Setup Test" 2>>"$LOG_FILE"; then
        log "测试文档已创建：$test_output"

        # 尝试预览
        if command -v pandoc &>/dev/null; then
            local preview
            preview=$(pandoc -f docx -t plain "$test_output" 2>/dev/null | head -5)
            if [ -n "$preview" ]; then
                log "预览工作正常：\"$preview\""
            fi
        fi

        # 清理
        rm -f "$test_output"
        log "测试通过 — minimax-docx 已就绪！"
    else
        fail "测试文档创建失败。检查 $LOG_FILE 了解详情。"
        return 1
    fi

    cd "$PROJECT_DIR"
}

# --- 摘要 ---
print_summary() {
    step "设置完成"

    echo ""
    echo "  环境：$OS ($ARCH)"
    echo "  .NET SDK：    $(dotnet --version 2>/dev/null || echo '未找到')"
    echo "  pandoc：      $(pandoc --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo '未安装（可选）')"
    echo "  soffice：     $(soffice --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' || echo '未安装（可选）')"
    echo "  项目：        $DOTNET_DIR"
    echo ""
    echo "  用法："
    echo "    dotnet run --project $DOTNET_DIR/MiniMaxAIDocx.Cli -- create --type report --output my_report.docx"
    echo "    bash $SCRIPT_DIR/env_check.sh     # 快速环境检查"
    echo ""
    echo "  日志文件：$LOG_FILE"
}

# --- 主函数 ---
main() {
    echo "============================================"
    echo "  minimax-docx 设置与初始化"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================"

    : > "$LOG_FILE"  # 清空日志

    detect_platform

    # 解析参数
    local SKIP_OPTIONAL=false
    local SKIP_VERIFY=false
    for arg in "$@"; do
        case "$arg" in
            --minimal)      SKIP_OPTIONAL=true ;;
            --skip-verify)  SKIP_VERIFY=true ;;
            --help|-h)
                echo "用法：setup.sh [选项]"
                echo "  --minimal       仅安装关键依赖项（跳过 pandoc、soffice、字体）"
                echo "  --skip-verify   跳过最后的验证测试"
                echo "  --help          显示此帮助"
                exit 0
                ;;
        esac
    done

    install_dotnet
    install_zip_tools

    if ! $SKIP_OPTIONAL; then
        install_pandoc
        install_soffice
        check_fonts
    fi

    check_locale
    check_nuget_config
    fix_permissions
    build_project

    if ! $SKIP_VERIFY; then
        verify_installation
    fi

    print_summary
}

main "$@"
