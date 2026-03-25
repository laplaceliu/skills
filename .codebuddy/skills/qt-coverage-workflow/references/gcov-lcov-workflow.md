# gcov + lcov 覆盖率工作流参考

## 前置条件

```bash
# Debian/Ubuntu
sudo apt-get install gcov lcov

# Fedora/RHEL
sudo dnf install gcc lcov

# macOS (需要 Homebrew 的 GCC; Apple Clang 使用 llvm-cov 替代)
brew install gcc lcov
```

注意: 在 macOS 上使用 Clang 时，将 `gcov` 引用替换为 `llvm-cov gcov`。

## CMake 覆盖率预设

### CMakePresets.json (推荐)

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "coverage",
      "displayName": "Coverage Build",
      "binaryDir": "${sourceDir}/build-coverage",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "ENABLE_COVERAGE": "ON"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "coverage",
      "configurePreset": "coverage"
    }
  ],
  "testPresets": [
    {
      "name": "coverage",
      "configurePreset": "coverage",
      "output": { "outputOnFailure": true }
    }
  ]
}
```

使用方法:
```bash
cmake --preset coverage
cmake --build --preset coverage
ctest --preset coverage
```

### CMakeLists.txt 覆盖率选项

```cmake
option(ENABLE_COVERAGE "Enable gcov/lcov coverage instrumentation" OFF)

if(ENABLE_COVERAGE)
    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        message(WARNING "Coverage builds should use Debug mode for accurate line mapping")
    endif()
    add_compile_options(-O0 -g --coverage -fprofile-arcs -ftest-coverage)
    add_link_options(--coverage)
    # Clang alternative: -fprofile-instr-generate -fcoverage-mapping
endif()
```

## 完整 lcov 工作流

```bash
#!/usr/bin/env bash
# 完整覆盖率收集流程

BUILD_DIR="build-coverage"
SRC_DIR="$(pwd)"
OUTPUT_DIR="htmlcov"

# 1. 构建
cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON
cmake --build "$BUILD_DIR" --parallel

# 2. 清除之前的计数器
lcov --zerocounters --directory "$BUILD_DIR"

# 3. 运行测试 (在构建目录生成 .gcda 文件)
cd "$BUILD_DIR"
ctest --output-on-failure
cd "$SRC_DIR"

# 4. 捕获覆盖率数据
lcov --capture \
     --directory "$BUILD_DIR" \
     --output-file coverage_raw.info \
     --no-external \             # 排除 /usr/include 和 Qt 头文件
     --gcov-tool gcov            # macOS Clang 使用 'llvm-cov gcov'

# 5. 移除噪音: 测试、moc 文件、UI 生成的文件
lcov --remove coverage_raw.info \
     '*/tests/*' \
     '*/moc_*' \
     '*/ui_*' \
     '*/build-coverage/*' \
     --output-file coverage.info

# 6. 显示摘要
lcov --summary coverage.info

# 7. 生成可浏览的 HTML 报告
genhtml coverage.info \
        --output-directory "$OUTPUT_DIR" \
        --title "$(basename $SRC_DIR) Coverage" \
        --legend \
        --show-details \
        --demangle-cpp            # 需要 c++filt

echo "Report: $OUTPUT_DIR/index.html"
```

## 解析覆盖率以识别差距

从 lcov 摘要中提取低于阈值的文件:

```bash
THRESHOLD=80

lcov --summary coverage.info 2>&1 | \
    grep "\.cpp\|\.h" | \
    awk -F'[(%]' '{
        file=$1; pct=$2
        if (pct+0 < '"$THRESHOLD"')
            print pct"% - "file
    }' | sort -n
```

从 lcov 数据文件中提取特定的未覆盖行:

```bash
# 解析 lcov .info 文件中 DA (行数据) 条目中命中计数为 0 的内容
grep -E "^(SF:|DA:)" coverage.info | \
    awk '/^SF:/{file=$0} /^DA:/{split($0,a,":"); split(a[2],b,","); if(b[2]==0) print file" line "b[1]}'
```

## Clang/LLVM 覆盖率替代方案

如果使用 Clang (特别是在 macOS 上):

```cmake
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
    add_link_options(-fprofile-instr-generate)
endif()
```

收集:
```bash
# 运行测试后:
llvm-profdata merge -sparse *.profraw -o coverage.profdata
llvm-cov report ./my_test -instr-profile=coverage.profdata
llvm-cov show ./my_test -instr-profile=coverage.profdata \
    -format=html -output-dir=htmlcov
```

## 故障排除

**`.gcda` 文件未生成**: 测试未运行，或使用了不同的二进制文件。在 `lcov --capture` 之前确认 `ctest` 成功运行。

**所有文件覆盖率显示 0%**: 编译标志中缺少 `-fprofile-arcs -ftest-coverage`。确认 `ENABLE_COVERAGE=ON` 实际生效。

**`--no-external` 遗漏了非系统路径的 Qt 头文件**: 如果 Qt 安装在自定义前缀 (非 `/usr`)，需要显式排除: `lcov --remove coverage_raw.info '/opt/qt6/*'`。

**`genhtml: demangle failed`**: 未安装 `c++filt`，或移除 `--demangle-cpp` 标志。

**不同运行结果**: 来自非检测构建的对象文件与检测构建的对象文件混合。在启用覆盖率后运行 `cmake --build --clean-first`。
