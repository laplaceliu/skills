# GUI 测试报告模板

`gui-tester` agent 将报告保存到 `tests/reports/gui-YYYY-MM-DD-HH-MM.md`。

## 报告格式

```markdown
# GUI Test Report — YYYY-MM-DD HH:MM

**App:** main.py
**Result:** PASS (4/4 interactions succeeded)

## Test Steps

| Step | Action | Expected | Result |
|------|--------|----------|--------|
| 1 | Click calculate_btn | result_label updates | ✅ PASS |
| 2 | Type "abc" in amount_input | Validation error shown | ✅ PASS |
| 3 | Press Escape | Dialog closes | ✅ PASS |
| 4 | Trigger save_action | File saved message | ✅ PASS |

## Screenshots
- [Before](screenshot_before.png)
- [After](screenshot_after.png)
```

## 字段描述

- **App** — 传递给 `launch_app` 的 `script_path` 或模块
- **Result** — 总体 PASS/FAIL 及 `(n/total interactions succeeded)` 计数
- **Test Steps table** — 每次交互一行; Result 为 `✅ PASS`、`❌ FAIL` 或 `⚠️ SKIP`
- **Screenshots** — 通过 `capture_screenshot` 保存的 PNG 文件的相对路径; 至少包含前后截图各一张，以及每次重要状态转换一张

## 命名约定

```
tests/reports/gui-YYYY-MM-DD-HH-MM.md
tests/reports/screenshot_before.png
tests/reports/screenshot_after.png
```

使用 ISO 8601 时间戳 (用连字符)，以便报告按日期 lexicographically 排序。

## FAIL 条目格式

当步骤失败时，在 Result 列中包含实际值与预期值的对比，并附加 **Failures** 部分:

```markdown
| 3 | get_widget_info("result_label") | text == "42.0" | ❌ FAIL — got "" |

## Failures

### Step 3 — result_label empty after click
- **Action**: click_widget("calculate_btn") → wait_for_idle() → get_widget_info("result_label")
- **Expected**: text = "42.0"
- **Actual**: text = "" (empty)
- **Likely cause**: Signal not connected — `calculate_btn.clicked` not wired to update slot
- **Screenshot**: [step3_failure.png](step3_failure.png)
```
