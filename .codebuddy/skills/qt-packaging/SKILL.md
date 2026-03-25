---
name: qt-packaging
description: >
  Qt Python 应用程序的打包与分发 — PyInstaller、Briefcase 以及平台特定的构建配置。适用于：将 PySide6 或 PyQt6 应用分发为独立可执行文件、创建安装程序、配置 macOS bundles、Windows 可执行文件或 Linux AppImages。

  触发词："package app"、"PyInstaller"、"distribute"、"deploy"、"standalone executable"、"installer"、"bundle app"、"briefcase"、"Windows build"、"macOS build"、"AppImage"、"one-file"
version: 1.0.0
---

## Qt Python 应用程序打包

### PyInstaller（最常用）

**关键：虚拟环境隔离**

Qt for Python 官方文档记录了一个已知的 PyInstaller 问题：**如果安装了系统级 PySide6，PyInstaller 会静默选择它而不是 venv 版本**。构建前请执行：

```bash
# 从构建机器上移除所有系统级 PySide6 安装
pip uninstall pyside6 pyside6_essentials pyside6_addons shiboken6 -y

# 验证只剩下 venv 版本
python -c "import PySide6; print(PySide6.__file__)"
# 必须显示 .venv/ 内的路径，而不是 /usr/lib 或系统 site-packages
```

**`--onefile` 限制：** 对于 Qt6，`--onefile` 打包无法自动部署 Qt 插件。单目录（`dist/MyApp/`）方式更可靠。仅在你了解其限制并手动处理 Qt 插件时才使用 `--onefile`。

**安装：**
```bash
uv add --dev pyinstaller
```

**基本单目录构建：**
```bash
pyinstaller --name MyApp \
  --windowed \
  --icon resources/icons/app.ico \
  src/myapp/__main__.py
```

**Spec 文件（可重现构建）：**
```python
# MyApp.spec
block_cipher = None

a = Analysis(
    ["src/myapp/__main__.py"],
    pathex=[],
    binaries=[],
    datas=[
        ("src/myapp/resources", "resources"),   # (源, 打包内的目标路径)
    ],
    hiddenimports=[
        "PySide6.QtSvg",          # SVG 支持
        "PySide6.QtSvgWidgets",   # SVG 组件
        "PySide6.QtXml",          # 部分 Qt 模块需要
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tkinter", "matplotlib"],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="MyApp",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,           # CLI 应用设为 True
    disable_windowed_traceback=False,
    argv_emulation=False,    # macOS：拖放文件时设为 True
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon="resources/icons/app.ico",
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="MyApp",
)
```

运行：`pyinstaller MyApp.spec`

**Qt 插件检测问题：** PySide6 通常需要显式导入插件。添加到 `hiddenimports`：
```python
hiddenimports = [
    "PySide6.QtSvg", "PySide6.QtSvgWidgets",
    "PySide6.QtPrintSupport",   # 部分平台上 QTextEdit 需要
    "PySide6.QtDBus",           # Linux
]
```

**QRC 编译资源：** 将编译后的 `.py` 资源文件包含在 `datas` 中，或确保它们可导入。最简洁的方式是在 `__init__.py` 中导入 `rc_resources`，让 PyInstaller 自动检测。

### Briefcase（跨平台，分发首选）

Briefcase 生成原生平台安装程序（`.msi`、`.dmg`、`.AppImage`）：

```bash
pip install briefcase
briefcase create     # 创建平台包
briefcase build      # 编译
briefcase run        # 从包运行
briefcase package    # 创建安装程序
```

**Briefcase 的 pyproject.toml：**
```toml
[tool.briefcase]
project_name = "MyApp"
bundle = "com.myorg.myapp"
version = "1.0.0"
url = "https://myorg.com"
license = "MIT"
author = "My Name"
author_email = "me@myorg.com"

[tool.briefcase.app.myapp]
formal_name = "My Application"
description = "Description here"
icon = "resources/icons/app"   # 不带扩展名 — briefcase 使用平台适格的格式
sources = ["src/myapp"]
requires = ["PySide6>=6.6"]
```

Briefcase 处理 Qt 插件打包比 PyInstaller 更可靠。

### Windows：windeployqt + 代码签名

PyInstaller 构建单目录包后，运行 `windeployqt`（来自 Qt SDK）来复制任何缺失的 Qt 插件和翻译：

```bash
# 从 Qt SDK tools 目录运行（或添加到 PATH）
windeployqt dist/MyApp/MyApp.exe
```

这确保平台插件（`qwindows.dll`）和其他 Qt 插件 DLL 存在。PyInstaller hooks 通常会自动收集它们，但 `windeployqt` 会捕获遗漏的部分。

```bash
# 为可执行文件签名（需要代码签名证书）
signtool sign /fd SHA256 /a /tr http://timestamp.digicert.com dist/MyApp.exe
```

未签名的 Windows 可执行文件会触发 SmartScreen 警告。对于内部分发，指导用户右键 → 属性 → 解除阻止。

### macOS：App Bundle

PyInstaller 生成 `.app` bundle。对于 App Store 以外的分发：
```bash
# Ad-hoc 签名（无开发者 ID）
codesign --force --deep --sign - dist/MyApp.app

# 使用开发者 ID
codesign --force --deep --sign "Developer ID Application: Name (TEAM_ID)" dist/MyApp.app

# 公证（Gatekeeper 要求）
xcrun notarytool submit dist/MyApp.zip --apple-id me@example.com --team-id TEAM_ID
```

### Linux：AppImage via PyInstaller

```bash
# 先构建单目录，然后打包为 AppImage
# 使用 https://github.com/AppImage/AppImageKit
appimagetool dist/MyApp/ MyApp-x86_64.AppImage
```

### 构建自动化（CI）

```yaml
# .github/workflows/build.yml
jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install pyinstaller PySide6
      - run: pyinstaller MyApp.spec
      - uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: dist/MyApp/
```

### 常见打包陷阱

- **缺失 Qt 平台插件**：`qt.qpa.plugin: Could not find the Qt platform plugin` — 确保 `PySide6/Qt/plugins/platforms/` 被包含。PyInstaller hooks 通常会处理此项；如未处理请重建。
- **缺失 SVG 支持**：在 `hiddenimports` 中导入 `PySide6.QtSvg`，否则加载 SVG 时应用会静默崩溃。
- **相对路径假设**：开发中使用 `Path(__file__).parent` 定位资源文件；PyInstaller 运行时路径使用 `sys._MEIPASS`（或通过 QRC 打包以完全避免此问题）。
- **macOS 上应用冻结**：如果应用需要处理文件关联，在 spec 中设置 `argv_emulation=True`。
