# Bootloader 与 OTA 固件更新指南

## 概述

Bootloader 是嵌入式系统的启动引导程序，负责硬件初始化、固件验证和应用程序跳转。OTA (Over-The-Air) 固件更新允许设备远程升级固件，无需物理连接。

## 内存布局设计

### 基本内存分区

```
STM32F4 典型 Flash 布局 (1MB Flash):
┌─────────────────────────────────────┐ 0x08000000
│         Bootloader (32KB)            │
│   - 启动代码                          │
│   - 固件验证                          │
│   - OTA 更新逻辑                       │
├─────────────────────────────────────┤ 0x08008000
│         Application (480KB)          │
│   - 主程序                            │
│   - 只读数据                          │
├─────────────────────────────────────┤ 0x08080000
│         OTA Storage (480KB)          │
│   - 新固件下载区                       │
│   - 临时存储                          │
├─────────────────────────────────────┤ 0x08100000
│         Configuration (16KB)         │
│   - OTA 状态                          │
│   - 设备配置                          │
│   - 固件元数据                         │
└─────────────────────────────────────┘ 0x08104000
```

### 链接脚本

```ld
/* bootloader.ld */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 32K
    RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 128K
}

SECTIONS
{
    .text : {
        *(.vector_table)
        *(.text*)
        *(.rodata*)
    } > FLASH
    
    .data : {
        *(.data*)
    } > RAM AT > FLASH
    
    .bss : {
        *(.bss*)
    } > RAM
}

/* application.ld */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08008000, LENGTH = 480K
    RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 128K
}

SECTIONS
{
    .text : {
        *(.vector_table)
        *(.text*)
        *(.rodata*)
    } > FLASH
    
    /* ... */
}

/* app_vector_table 偏移 */
SCB->VTOR = 0x08008000;
```

---

## 2. Bootloader 设计

### 启动流程

```
上电复位
    │
    ▼
┌──────────────┐
│ Bootloader   │
│ 启动         │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 检查 OTA     │
│ 请求标志     │────► OTA 更新模式
└──────┬───────┘
       │ 无 OTA 请求
       ▼
┌──────────────┐
│ 验证应用     │
│ 固件完整性   │────► 恢复模式
└──────┬───────┘
       │ 验证通过
       ▼
┌──────────────┐
│ 跳转到应用   │
└──────────────┘
```

### Bootloader 实现

```cpp
// bootloader/main.cpp
#include "stm32f4xx_hal.h"
#include "flash_interface.h"
#include "firmware_validator.h"
#include "ota_manager.h"

// 内存地址定义
constexpr uint32_t APP_ADDRESS = 0x08008000;
constexpr uint32_t OTA_ADDRESS = 0x08080000;
constexpr uint32_t CONFIG_ADDRESS = 0x08100000;

// 固件元数据
struct FirmwareMetadata {
    uint32_t magic;           // 魔数: 0xDEADBEEF
    uint32_t version;         // 固件版本
    uint32_t size;            // 固件大小
    uint32_t crc32;           // CRC32 校验
    uint32_t build_timestamp; // 构建时间戳
    uint8_t reserved[44];     // 保留字段
} __attribute__((packed));

// OTA 状态
struct OtaStatus {
    uint32_t magic;           // 魔数
    uint32_t state;           // 状态: 0=空闲, 1=下载中, 2=待安装
    uint32_t download_size;   // 已下载大小
    uint32_t total_size;      // 总大小
    uint32_t retry_count;     // 重试次数
};

class Bootloader {
public:
    void run() {
        // 1. 硬件初始化
        init_hardware();
        
        // 2. 检查 OTA 状态
        if (check_ota_request()) {
            handle_ota_update();
        }
        
        // 3. 验证应用程序
        if (validate_application()) {
            jump_to_application();
        } else {
            handle_invalid_firmware();
        }
    }
    
private:
    void init_hardware() {
        HAL_Init();
        SystemClock_Config();
        
        // 初始化串口用于调试输出
        uart_.init(115200);
        uart_.write_string("\r\nBootloader v1.0\r\n");
    }
    
    bool check_ota_request() {
        OtaStatus status;
        flash_.read(CONFIG_ADDRESS, &status, sizeof(status));
        
        return status.magic == OTA_MAGIC && status.state == OTA_STATE_PENDING;
    }
    
    void handle_ota_update() {
        uart_.write_string("OTA update pending...\r\n");
        
        // 验证下载的固件
        FirmwareMetadata metadata;
        flash_.read(OTA_ADDRESS, &metadata, sizeof(metadata));
        
        if (verify_firmware(OTA_ADDRESS, metadata)) {
            uart_.write_string("Copying new firmware...\r\n");
            
            // 复制固件到应用区
            copy_firmware(OTA_ADDRESS, APP_ADDRESS, metadata.size);
            
            // 更新状态
            OtaStatus status = {
                .magic = OTA_MAGIC,
                .state = OTA_STATE_COMPLETED,
            };
            flash_.write(CONFIG_ADDRESS, &status, sizeof(status));
            
            uart_.write_string("OTA update completed\r\n");
        } else {
            uart_.write_string("OTA firmware invalid\r\n");
            
            // 清除 OTA 状态
            OtaStatus status = {.magic = OTA_MAGIC, .state = OTA_STATE_IDLE};
            flash_.write(CONFIG_ADDRESS, &status, sizeof(status));
        }
    }
    
    bool validate_application() {
        FirmwareMetadata metadata;
        flash_.read(APP_ADDRESS, &metadata, sizeof(metadata));
        
        if (metadata.magic != FIRMWARE_MAGIC) {
            uart_.write_string("Invalid firmware magic\r\n");
            return false;
        }
        
        return verify_firmware(APP_ADDRESS, metadata);
    }
    
    bool verify_firmware(uint32_t address, const FirmwareMetadata& metadata) {
        uart_.write_string("Verifying firmware...\r\n");
        
        // 验证 CRC
        uint32_t calculated_crc = calculate_crc32(
            address + sizeof(FirmwareMetadata),
            metadata.size
        );
        
        if (calculated_crc != metadata.crc32) {
            uart_.write_string("CRC mismatch\r\n");
            return false;
        }
        
        uart_.write_string("Firmware verified OK\r\n");
        return true;
    }
    
    void jump_to_application() {
        uart_.write_string("Jumping to application...\r\n");
        
        // 1. 禁用所有中断
        __disable_irq();
        
        // 2. 清除所有外设中断标志
        for (int i = 0; i < 8; ++i) {
            NVIC->ICER[i] = 0xFFFFFFFF;
            NVIC->ICPR[i] = 0xFFFFFFFF;
        }
        
        // 3. 设置向量表偏移
        SCB->VTOR = APP_ADDRESS;
        
        // 4. 设置主堆栈指针 (MSP)
        uint32_t app_stack = *reinterpret_cast<uint32_t*>(APP_ADDRESS);
        __set_MSP(app_stack);
        
        // 5. 跳转到应用复位处理
        uint32_t app_entry = *reinterpret_cast<uint32_t*>(APP_ADDRESS + 4);
        using EntryPoint = void(*)();
        EntryPoint entry = reinterpret_cast<EntryPoint>(app_entry);
        
        entry();
    }
    
    void handle_invalid_firmware() {
        uart_.write_string("Invalid firmware, entering recovery mode\r\n");
        
        // 进入恢复模式，等待固件更新
        while (true) {
            // 可以通过串口或其他接口接收新固件
            delay_ms(1000);
            uart_.write_string("Waiting for firmware...\r\n");
        }
    }
    
    FlashInterface flash_;
    UartInterface uart_;
};

int main() {
    Bootloader bootloader;
    bootloader.run();
    
    while (true) {}
}
```

---

## 3. OTA 固件更新

### OTA 状态机

```cpp
// ota_manager.hpp
class OtaManager {
public:
    enum class State {
        Idle,           // 空闲
        Downloading,    // 下载中
        Verifying,      // 验证中
        Ready,          // 准备安装
        Installing,     // 安装中
        Error           // 错误
    };
    
    struct Progress {
        State state;
        uint32_t downloaded;
        uint32_t total;
        uint8_t percentage;
    };
    
    // 开始 OTA 更新
    ErrorCode::Code start_update(uint32_t total_size) {
        if (state_ != State::Idle) {
            return ErrorCode::OtaBusy;
        }
        
        total_size_ = total_size;
        downloaded_ = 0;
        state_ = State::Downloading;
        
        // 擦除 OTA 区域
        flash_.erase(OTA_ADDRESS, total_size);
        
        // 写入初始元数据
        FirmwareMetadata metadata = {
            .magic = FIRMWARE_MAGIC,
            .size = total_size,
            .crc32 = 0,  // 稍后计算
        };
        flash_.write(OTA_ADDRESS, &metadata, sizeof(metadata));
        
        write_offset_ = sizeof(FirmwareMetadata);
        
        return ErrorCode::None;
    }
    
    // 写入固件数据块
    ErrorCode::Code write_chunk(const uint8_t* data, size_t length) {
        if (state_ != State::Downloading) {
            return ErrorCode::OtaInvalidState;
        }
        
        // 写入 Flash
        flash_.write(OTA_ADDRESS + write_offset_, data, length);
        
        write_offset_ += length;
        downloaded_ += length;
        
        // 更新进度
        update_progress();
        
        // 检查是否完成
        if (downloaded_ >= total_size_) {
            state_ = State::Verifying;
            verify_firmware();
        }
        
        return ErrorCode::None;
    }
    
    // 完成更新并请求安装
    ErrorCode::Code complete_update() {
        if (state_ != State::Ready) {
            return ErrorCode::OtaInvalidState;
        }
        
        // 设置 OTA 待安装标志
        OtaStatus status = {
            .magic = OTA_MAGIC,
            .state = OTA_STATE_PENDING,
            .total_size = total_size_,
        };
        flash_.write(CONFIG_ADDRESS, &status, sizeof(status));
        
        // 重启以进入 Bootloader
        NVIC_SystemReset();
        
        return ErrorCode::None;  // 不会执行到这里
    }
    
    Progress get_progress() const {
        return {
            .state = state_,
            .downloaded = downloaded_,
            .total = total_size_,
            .percentage = static_cast<uint8_t>((downloaded_ * 100) / total_size_),
        };
    }
    
private:
    void verify_firmware() {
        FirmwareMetadata metadata;
        flash_.read(OTA_ADDRESS, &metadata, sizeof(metadata));
        
        // 计算 CRC
        metadata.crc32 = calculate_crc32(
            OTA_ADDRESS + sizeof(FirmwareMetadata),
            metadata.size
        );
        
        // 更新元数据
        flash_.write(OTA_ADDRESS, &metadata, sizeof(metadata));
        
        state_ = State::Ready;
    }
    
    FlashInterface flash_;
    State state_ = State::Idle;
    uint32_t total_size_ = 0;
    uint32_t downloaded_ = 0;
    uint32_t write_offset_ = 0;
};
```

### 通信协议

```cpp
// OTA 通信协议
namespace OtaProtocol {
    // 命令定义
    enum class Command : uint8_t {
        StartUpdate     = 0x01,
        WriteChunk      = 0x02,
        CompleteUpdate  = 0x03,
        GetProgress     = 0x04,
        AbortUpdate     = 0x05,
    };
    
    // 响应定义
    enum class Response : uint8_t {
        Ok              = 0x00,
        Error           = 0x01,
        InvalidState    = 0x02,
        ChecksumError   = 0x03,
    };
    
    // 数据包格式
    struct Packet {
        uint8_t start;      // 0xAA
        uint8_t command;
        uint16_t length;
        uint8_t data[256];
        uint8_t checksum;
    } __attribute__((packed));
    
    // 协议处理器
    class ProtocolHandler {
    public:
        void process(const uint8_t* data, size_t length) {
            // 解析数据包
            Packet packet;
            if (!parse_packet(data, length, packet)) {
                send_response(Response::Error);
                return;
            }
            
            // 处理命令
            switch (static_cast<Command>(packet.command)) {
                case Command::StartUpdate: {
                    uint32_t total_size = *reinterpret_cast<uint32_t*>(packet.data);
                    ErrorCode::Code err = ota_manager_.start_update(total_size);
                    send_response(err == ErrorCode::None ? Response::Ok : Response::Error);
                    break;
                }
                
                case Command::WriteChunk: {
                    ErrorCode::Code err = ota_manager_.write_chunk(
                        packet.data, packet.length
                    );
                    send_response(err == ErrorCode::None ? Response::Ok : Response::Error);
                    break;
                }
                
                case Command::CompleteUpdate: {
                    ErrorCode::Code err = ota_manager_.complete_update();
                    send_response(err == ErrorCode::None ? Response::Ok : Response::Error);
                    break;
                }
                
                case Command::GetProgress: {
                    auto progress = ota_manager_.get_progress();
                    uint8_t data[] = {
                        static_cast<uint8_t>(progress.state),
                        static_cast<uint8_t>(progress.percentage),
                    };
                    send_data(data, sizeof(data));
                    break;
                }
                
                default:
                    send_response(Response::Error);
                    break;
            }
        }
        
    private:
        void send_response(Response response) {
            uint8_t data[] = {0xAA, 0x00, 0x01, static_cast<uint8_t>(response), 0x00};
            data[4] = calculate_checksum(data, 4);
            uart_.write(data, sizeof(data));
        }
        
        OtaManager ota_manager_;
        UartInterface uart_;
    };
}
```

---

## 4. 安全启动 (Secure Boot)

### 固件签名

```cpp
// 使用 ECDSA 签名验证固件
#include "mbedtls/ecdsa.h"
#include "mbedtls/sha256.h"

class SecureBoot {
public:
    bool verify_signature(uint32_t firmware_address, uint32_t firmware_size) {
        // 1. 读取签名 (存储在固件末尾)
        uint8_t signature[64];
        flash_.read(firmware_address + firmware_size, signature, sizeof(signature));
        
        // 2. 计算固件哈希
        uint8_t hash[32];
        calculate_sha256(firmware_address, firmware_size, hash);
        
        // 3. 使用公钥验证签名
        return verify_ecdsa_signature(hash, signature);
    }
    
private:
    void calculate_sha256(uint32_t address, uint32_t size, uint8_t* hash) {
        mbedtls_sha256_context ctx;
        mbedtls_sha256_init(&ctx);
        mbedtls_sha256_starts(&ctx, 0);
        
        // 分块计算哈希
        uint8_t buffer[256];
        uint32_t offset = 0;
        
        while (offset < size) {
            uint32_t chunk_size = std::min(sizeof(buffer), size - offset);
            flash_.read(address + offset, buffer, chunk_size);
            mbedtls_sha256_update(&ctx, buffer, chunk_size);
            offset += chunk_size;
        }
        
        mbedtls_sha256_finish(&ctx, hash);
        mbedtls_sha256_free(&ctx);
    }
    
    bool verify_ecdsa_signature(const uint8_t* hash, const uint8_t* signature) {
        // 使用内置公钥验证签名
        // 公钥应该存储在 Bootloader 中
        mbedtls_ecp_group grp;
        mbedtls_ecp_point Q;
        mbedtls_mpi r, s;
        
        mbedtls_ecp_group_init(&grp);
        mbedtls_ecp_point_init(&Q);
        mbedtls_mpi_init(&r);
        mbedtls_mpi_init(&s);
        
        // 加载公钥和签名
        load_public_key(&grp, &Q);
        mbedtls_mpi_read_binary(&r, signature, 32);
        mbedtls_mpi_read_binary(&s, signature + 32, 32);
        
        // 验证签名
        int ret = mbedtls_ecdsa_verify(&grp, hash, 32, &Q, &r, &s);
        
        mbedtls_ecp_group_free(&grp);
        mbedtls_ecp_point_free(&Q);
        mbedtls_mpi_free(&r);
        mbedtls_mpi_free(&s);
        
        return ret == 0;
    }
    
    // 内置公钥 (编译时嵌入)
    static constexpr uint8_t PUBLIC_KEY[] = {
        /* 公钥数据 */
    };
    
    FlashInterface flash_;
};
```

### 回滚保护

```cpp
// 防止降级攻击
class RollbackProtection {
public:
    bool check_version(uint32_t new_version) {
        uint32_t current_version = get_current_version();
        
        // 新版本必须大于当前版本
        if (new_version <= current_version) {
            return false;
        }
        
        return true;
    }
    
    void update_version(uint32_t new_version) {
        // 将版本号写入一次性可编程 (OTP) 区域
        // 或写入 Flash 配置区
        flash_.write(VERSION_ADDRESS, &new_version, sizeof(new_version));
    }
    
private:
    uint32_t get_current_version() {
        uint32_t version;
        flash_.read(VERSION_ADDRESS, &version, sizeof(version));
        return version;
    }
    
    FlashInterface flash_;
    static constexpr uint32_t VERSION_ADDRESS = 0x08100000;
};
```

---

## 5. 双分区 OTA (A/B 更新)

### 双分区布局

```
双分区布局 (更安全):
┌─────────────────────────────────────┐ 0x08000000
│         Bootloader (32KB)            │
├─────────────────────────────────────┤ 0x08008000
│         Partition A (480KB)          │
│   当前运行的固件                       │
├─────────────────────────────────────┤ 0x08080000
│         Partition B (480KB)          │
│   新固件下载区                         │
├─────────────────────────────────────┤ 0x08100000
│         Configuration (16KB)         │
│   - 活动分区标志                       │
│   - 启动计数器                         │
│   - 版本信息                           │
└─────────────────────────────────────┘
```

### 双分区管理

```cpp
class DualBankOta {
public:
    enum class Partition { A, B };
    
    struct BootConfig {
        Partition active;           // 当前活动分区
        uint32_t boot_count;        // 启动计数
        uint32_t boot_success;      // 成功启动计数
        uint32_t version_a;         // 分区 A 版本
        uint32_t version_b;         // 分区 B 版本
    };
    
    void boot() {
        BootConfig config = read_boot_config();
        
        // 检查启动计数，防止启动循环
        if (config.boot_count > MAX_BOOT_ATTEMPTS) {
            // 切换到另一个分区
            switch_partition(config);
        }
        
        // 增加启动计数
        config.boot_count++;
        write_boot_config(config);
        
        // 跳转到活动分区
        uint32_t app_address = (config.active == Partition::A) 
            ? PARTITION_A_ADDRESS 
            : PARTITION_B_ADDRESS;
        
        jump_to_application(app_address);
    }
    
    void mark_boot_successful() {
        BootConfig config = read_boot_config();
        config.boot_success++;
        config.boot_count = 0;  // 重置启动计数
        write_boot_config(config);
    }
    
    void switch_partition(BootConfig& config) {
        config.active = (config.active == Partition::A) ? Partition::B : Partition::A;
        config.boot_count = 0;
        write_boot_config(config);
    }
    
private:
    BootConfig read_boot_config() {
        BootConfig config;
        flash_.read(CONFIG_ADDRESS, &config, sizeof(config));
        return config;
    }
    
    void write_boot_config(const BootConfig& config) {
        flash_.erase(CONFIG_ADDRESS, sizeof(config));
        flash_.write(CONFIG_ADDRESS, &config, sizeof(config));
    }
    
    static constexpr uint32_t MAX_BOOT_ATTEMPTS = 3;
    static constexpr uint32_t PARTITION_A_ADDRESS = 0x08008000;
    static constexpr uint32_t PARTITION_B_ADDRESS = 0x08080000;
    static constexpr uint32_t CONFIG_ADDRESS = 0x08100000;
    
    FlashInterface flash_;
};
```

---

## 检查清单

### Bootloader 开发

- [ ] 内存布局规划完成
- [ ] 链接脚本配置正确
- [ ] 启动代码实现
- [ ] 固件验证机制
- [ ] 应用跳转逻辑
- [ ] 恢复模式实现
- [ ] 调试输出正常

### OTA 更新

- [ ] 固件下载机制
- [ ] 断点续传支持
- [ ] CRC/签名验证
- [ ] 回滚保护
- [ ] 进度报告
- [ ] 错误处理
- [ ] 状态持久化

### 安全性

- [ ] 固件签名验证
- [ ] 回滚保护
- [ ] 安全存储密钥
- [ ] 防止降级攻击
- [ ] 启动循环检测

### 可靠性

- [ ] 断电保护
- [ ] 写入验证
- [ ] 双分区备份 (可选)
- [ ] 看门狗保护
- [ ] 自动回滚
