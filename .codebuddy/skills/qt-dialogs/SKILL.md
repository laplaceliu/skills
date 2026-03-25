---
name: qt-dialogs
description: >
  Qt C++ 对话框模式 — QDialog、QMessageBox、QFileDialog、QInputDialog 以及自定义模态/非模态对话框。当需要创建确认提示、文件选择器、设置对话框、自定义数据输入对话框或向导式多步对话框时使用此技能。

  触发短语："dialog"、"QMessageBox"、"QFileDialog"、"QInputDialog"、"modal"、"modeless"、"settings dialog"、"confirm dialog"、"custom dialog"、"file picker"、"wizard"、"popup"
version: 1.0.0
---

## Qt C++ 对话框模式

### QMessageBox — 标准提示

```cpp
#include <QMessageBox>

// 确认对话框
bool confirmDelete(QWidget *parent, const QString &itemName) {
    QMessageBox::StandardButton result = QMessageBox::question(
        parent,
        "Confirm Delete",
        QString("Delete '%1'? This cannot be undone.").arg(itemName),
        QMessageBox::Yes | QMessageBox::No,
        QMessageBox::No  // 默认按钮
    );
    return result == QMessageBox::Yes;
}

// 错误
QMessageBox::critical(parent, "Error",
    QString("Failed to save: %1").arg(error));

// 警告
QMessageBox::warning(parent, "Warning",
    "File already exists. Overwrite?");

// 信息
QMessageBox::information(parent, "Done",
    "Export completed successfully.");

// 自定义按钮
QMessageBox msgBox(parent);
msgBox.setWindowTitle("Unsaved Changes");
msgBox.setText("You have unsaved changes.");
msgBox.setInformativeText("Do you want to save before closing?");

QPushButton *saveBtn = msgBox.addButton("Save",
    QMessageBox::AcceptRole);
QPushButton *discardBtn = msgBox.addButton("Discard",
    QMessageBox::DestructiveRole);
msgBox.addButton(QMessageBox::Cancel);
msgBox.exec();

if (msgBox.clickedButton() == saveBtn) {
    save();
} else if (msgBox.clickedButton() == discardBtn) {
    // 丢弃
}
// 否则：取消 — 不做任何事
```

### QFileDialog — 文件和目录选择器

```cpp
#include <QFileDialog>
#include <QDir>

// 打开单个文件
QString path = QFileDialog::getOpenFileName(
    parent,
    "Open File",
    QDir::homePath(),
    "CSV Files (*.csv);;Text Files (*.txt);;All Files (*)"
);
if (!path.isEmpty()) {
    load(path);
}

// 打开多个文件
QStringList paths = QFileDialog::getOpenFileNames(
    parent,
    "Select Images",
    "",
    "Images (*.png *.jpg *.svg)"
);

// 保存文件
QString savePath = QFileDialog::getSaveFileName(
    parent,
    "Save As",
    "export.csv",
    "CSV (*.csv)"
);
if (!savePath.isEmpty()) {
    exportTo(savePath);
}

// 选择目录
QString directory = QFileDialog::getExistingDirectory(
    parent,
    "Select Output Folder"
);
```

过滤器字符串格式为 `"Description (*.ext *.ext2);;Description2 (*.ext3)"`。

### 自定义 QDialog

```cpp
// addpersondialog.h
#pragma once
#include <QDialog>
#include <QVBoxLayout>
#include <QFormLayout>
#include <QLineEdit>
#include <QDialogButtonBox>
#include <QMessageBox>

class AddPersonDialog : public QDialog {
    Q_OBJECT

public:
    explicit AddPersonDialog(QWidget *parent = nullptr);
    QString name() const;
    QString email() const;

private slots:
    void accept() override;

private:
    void setupUi();

    QLineEdit *m_nameEdit = nullptr;
    QLineEdit *m_emailEdit = nullptr;
};
```

```cpp
// addpersondialog.cpp
#include "addpersondialog.h"

AddPersonDialog::AddPersonDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("Add Person");
    setModal(true);
    setMinimumWidth(300);
    setupUi();
}

void AddPersonDialog::setupUi() {
    QVBoxLayout *layout = new QVBoxLayout(this);

    QFormLayout *form = new QFormLayout();

    m_nameEdit = new QLineEdit(this);
    m_nameEdit->setPlaceholderText("Full name");
    m_emailEdit = new QLineEdit(this);
    m_emailEdit->setPlaceholderText("email@example.com");

    form->addRow("Name:", m_nameEdit);
    form->addRow("Email:", m_emailEdit);
    layout->addLayout(form);

    QDialogButtonBox *buttons = new QDialogButtonBox(
        QDialogButtonBox::Ok | QDialogButtonBox::Cancel,
        this
    );
    connect(buttons, &QDialogButtonBox::accepted,
            this, &AddPersonDialog::accept);
    connect(buttons, &QDialogButtonBox::rejected,
            this, &QDialog::reject);
    layout->addWidget(buttons);
}

void AddPersonDialog::accept() {
    if (m_nameEdit->text().trimmed().isEmpty()) {
        QMessageBox::warning(this, "Validation", "Name is required.");
        return;
    }
    QDialog::accept();
}

QString AddPersonDialog::name() const {
    return m_nameEdit->text().trimmed();
}

QString AddPersonDialog::email() const {
    return m_emailEdit->text().trimmed();
}
```

使用 `QDialogButtonBox` 获取标准按钮 — 它遵守平台按钮顺序约定（OK/取消 vs 取消/OK）。

### 模态 vs 非模态

```cpp
// 模态 — 阻止对父窗口的输入
dialog.setModal(true);
dialog.exec();      // 阻塞直到关闭

// 非模态 — 用户可以与父窗口交互
dialog.setModal(false);
dialog.show();      // 非阻塞
dialog.raise();     // 带到前面
dialog.activateWindow();
```

对于非模态对话框，请使用成员变量保留引用以防止对象被销毁：

```cpp
// mainwindow.h
private:
    SettingsDialog *m_settingsDialog = nullptr;

// mainwindow.cpp
void MainWindow::onSettingsClicked() {
    if (!m_settingsDialog) {
        m_settingsDialog = new SettingsDialog(this);
    }
    m_settingsDialog->show();
}
```

### 设置对话框模式

设置对话框应该实时应用更改（更改时）或在明确点击确定时应用：

```cpp
// settingsdialog.h
#pragma once
#include <QDialog>
#include <QComboBox>
#include <QSpinBox>
#include <QDialogButtonBox>
#include <QHash>

class SettingsDialog : public QDialog {
    Q_OBJECT

public:
    explicit SettingsDialog(const QHash<QString, QVariant> &settings,
                           QWidget *parent = nullptr);
    QHash<QString, QVariant> currentSettings() const;

signals:
    void settingsChanged(const QHash<QString, QVariant> &settings);

private slots:
    void onChanged();

private:
    void setupUi();

    QHash<QString, QVariant> m_originalSettings;
    QHash<QString, QVariant> m_currentSettings;

    QComboBox *m_themeCombo = nullptr;
    QSpinBox *m_fontSizeSpin = nullptr;
};

SettingsDialog::SettingsDialog(const QHash<QString, QVariant> &settings,
                               QWidget *parent)
    : QDialog(parent)
    , m_originalSettings(settings)
    , m_currentSettings(settings)
{
    setupUi();
}

void SettingsDialog::setupUi() {
    // ... UI setup ...

    connect(m_themeCombo, &QComboBox::currentTextChanged,
            this, &SettingsDialog::onChanged);
}

void SettingsDialog::onChanged() {
    m_currentSettings["theme"] = m_themeCombo->currentText();
    emit settingsChanged(m_currentSettings);  // 实时预览
}

void SettingsDialog::reject() {
    emit settingsChanged(m_originalSettings);  // 取消时恢复
    QDialog::reject();
}
```
