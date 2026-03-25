---
name: qt-packaging
description: >
  Qt C++ 应用程序的打包与分发 — CMake、Conan、vcpkg、安装程序以及平台特定的构建配置。适用于：将 Qt C++ 应用分发为独立可执行文件、创建安装程序、配置 macOS bundles、Windows 可执行文件或 Linux AppImages。

  触发词："package app"、"CMake"、"conan"、"vcpkg"、"distribute"、"deploy"、"standalone executable"、"installer"、"bundle app"、"Windows build"、"macOS build"、"AppImage"、"cmake install"
version: 1.0.0
---

## Qt C++ 应用程序打包

### CMake + Qt6 推荐配置

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 自动处理 Qt 元对象编译
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

qt_standard_project_setup()

add_executable(myapp
    src/main.cpp
    src/mainwindow.cpp
    src/mainwindow.h
    # ... 其他源文件
)

target_link_libraries(myapp PRIVATE Qt6::Widgets)

# 资源文件
qt_add_resources(myapp "resources"
    PREFIX "/"
    FILES
        resources/icons/app.png
        resources/themes/dark.qss
)
```

### Conan + vcpkg 依赖管理

**Conan:**
```bash
# conanfile.txt
[requires]
qt/6.5.0

[generators]
cmake_find_package
cmake_paths

# 构建
conan install . -if build -c Tools.toolchain:cmake_layout=True
cmake -B build -sf build -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build build
```

**vcpkg:**
```bash
# 安装 Qt
vcpkg install qtbase:x64-osx qt5:image

# CMake Toolchain
cmake -B build -DCMAKE_TOOLCHAIN_FILE=[vcpkg]/scripts/buildsystems/vcpkg.cmake
```

### Windows：单独可执行文件

使用 `windeployqt` 部署 Qt 运行时和插件：

```bash
# 构建发布版本
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release

# 部署 Qt 依赖
windeployqt build/Release/myapp.exe --no-translations

# 创建自包含安装包
# 使用 NSIS、WiX 或 Inno Setup
```

**CMake Install 规则：**
```cmake
install(TARGETS myapp
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
)

install(DIRECTORY resources/
    DESTINATION share/myapp/resources
)
```

### macOS：App Bundle

```cmake
# macOS Bundle 配置
set_target_properties(myapp PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.myorg.myapp"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
    MACOSX_BUNDLE_LONG_VERSION_STRING "1.0.0"
    MACOSX_RPATH TRUE
)

# 部署 Qt 和插件
qt_generate_deploy_app_script(
    TARGET myapp
    OUTPUT_SCRIPT deploy_script
    NO_UNITY_BUILD
)

install(CODE "include(${deploy_script})")
```

```bash
# 构建
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release

# 部署
./build/deploy_script --appfolder MyApp.app

# 签名（Ad-hoc）
codesign --force --deep --sign - MyApp.app

# 或使用开发者 ID
codesign --force --deep --sign "Developer ID Application: Name (TEAM_ID)" MyApp.app

# 公证（Gatekeeper 要求）
xcrun notarytool submit MyApp.zip --apple-id me@example.com --team-id TEAM_ID --wait
```

### Linux：AppImage

```bash
# 安装 linuxdeployqt
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

# 构建
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# 部署
# 需要先创建 AppRun 脚本
export QTDIR=/path/to/qt6
./linuxdeploy-x86_64.AppImage --appimage-extract-and-run \
    --executable build/myapp \
    --plugin qt \
    --output appimage
```

### CMake Install + CPack

```cmake
# 安装规则
install(TARGETS myapp
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION Applications
)

install(DIRECTORY resources/icons/
    DESTINATION share/myapp/icons
)

# CPack 配置
set(CPACK_PACKAGE_NAME "MyApp")
set(CPACK_PACKAGE_VENDOR "My Organization")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_CONTACT "me@myorg.com")

# 生成安装程序
set(CPACK_GENERATOR "NSIS")        # Windows
set(CPACK_GENERATOR "TGZ")         # Linux
set(CPACK_GENERATOR "ZIP")          # macOS

include(CPack)
```

```bash
# 构建并打包
cmake --build build --config Release
cmake --install build --config Release
# 或使用 cpack
cpack --config build/CPackConfig.cmake
```

### Qt 插件部署

Qt 插件必须放在正确的子目录中：

```
myapp/
├── bin/
│   └── myapp
├── plugins/
│   ├── platforms/
│   │   └── qwindows.dll      # Windows
│   ├── platforms/
│   │   └── libqcocoa.dylib    # macOS
│   ├── imageformats/
│   │   └── libqsvg.dll
│   └── styles/
├── resources/
└── translations/
```

**CMake 自动处理：**
```cmake
qt_generate_deploy_app_script(
    TARGET myapp
    OUTPUT_SCRIPT deploy_script
)

# 在 install() 中调用
install(CODE "include(${deploy_script})")
```

### CMake Bundling

使用 `Qt6::qmake` 获取 Qt 依赖：
```cmake
find_package(Qt6 REQUIRED COMPONENTS Widgets)

# 让 Qt 自动找到插件
get_target_property(QtCore_import_prefix Qt6::Core import_prefix)
set(Qt6_DIR ${QtCore_import_prefix}/../../../cmake/Qt6)
```

### 常见打包陷阱

- **缺失 Qt 平台插件**：`qt.qpa.plugin: Could not find the Qt platform plugin` — 确保 `windeployqt` 或 `macdeployqt` 已运行
- **缺失 SVG 支持**：确保 `imageformats` 插件被包含
- **相对路径假设**：使用 `QCoreApplication::applicationDirPath()` 定位资源文件；发布时使用 QRC 打包以完全避免此问题
- **macOS 上应用冻结**：如果应用需要处理文件关联，在 Info.plist 中设置 `NSAppleEventsUsageDescription`

### CI/CD 自动化

**GitHub Actions：**
```yaml
# .github/workflows/build.yml
jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Qt
        uses: jurplel/qt-action@v3
        with:
          version: 6.5.0
      - name: Configure
        run: cmake -B build -DCMAKE_BUILD_TYPE=Release
      - name: Build
        run: cmake --build build --config Release
      - name: Deploy
        run: windeployqt build/Release/myapp.exe
      - uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: build/Release/
```
