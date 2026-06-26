# 💊 家庭用药管家 (Medication Reminder)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-^3.9.2-0175C2?logo=dart)](https://dart.dev)
[![Platform Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://www.android.com)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

一个基于 Flutter 与 Material Design 3 (M3) 规范构建的家庭端药品服用管理与提醒系统。不仅帮助个人患者科学地规范服药、管理库存、记录症状药效，还支持家属端授权绑定与远程监护。

---

## 🌟 核心功能特性

### 1. 🔬 药品与库存管理
* **全面记录**：支持录入药品名、剂型（胶囊/片剂/冲剂/液体等）、规格包装、文字备注等。
* **低库存预警**：支持自定义每种药品的“库存预警阈值”，在每日用药确认后**自动扣减库存**，并在主页触发红底警告，防范忘买断药。

### 2. 📅 灵活智能服药计划
* **多维度频次**：支持“每日服药”、“每周特定天”、“每月特定日”以及“PRN (按需服用)”四类方案。
* **按需用药 (PRN) 限制**：设定每日最大服用次数与最小服用时间间隔（分钟），防止超量滥用。
* **时段分组**：支持在单个计划内灵活配置多个服药时间点，并自动适配时段逻辑。

### 3. ⏰ 智能提醒与服药追踪
* **周视图状态栏**：主页顶部配备结合农历算法的 7 日用药连续天数打卡统计条。
* **快捷操作弹窗**：支持通过底部 Sheet 快速记录服药情况，提供“已服药”、“延迟 15 分钟”、“跳过本次”等策略。
* **系统通知**：集成本地通知通知渠道，确保到点强力提醒。

### 4. 📓 症状日记与药效监测
* **程度量化**：支持 1~5 级严重程度的身体症状记录。
* **药效追踪**：症状可关联特定服用药品，直观显示用药与健康症状改善的对比关联。

### 5. 👥 家属授权监护模式
* **双端绑定**：通过手机号申请绑定，建立看护连接。
* **状态查看**：监护人可在专属界面中远程调阅被看护人的今日服药进度、用药依从率及近期的连续服药天数。

---

## 🛠️ 技术栈选型

| 模块类别 | 选型技术 / 依赖组件 | 说明 |
| :--- | :--- | :--- |
| **应用核心** | `Flutter 3.x` / `Dart ^3.9.2` | 提供高性能、跨平台基础运行环境 |
| **状态管理** | `Provider` (`ChangeNotifier`) | 统一处理数据更新通知，UI 与逻辑分离 |
| **本地存储** | `sqflite` (SQLite) | 结构化管理 5 张业务主表（药品、计划、提醒、症状、家属绑定） |
| **导航路由** | `go_router` | 提供声明式路由，支持深度传参及嵌套 |
| **推送通知** | `flutter_local_notifications` | 负责时间点本地通知的精确调配 |
| **UI 主题** | `Material Design 3` | 主色调设为 `#C62828`（温和医疗红），全面适配深色模式 |

---

## 📂 解耦后项目文件结构 (`lib/`)

项目经过系统化重构，核心的 `PatientHomeScreen` 已由千行大类解耦为高度模块化的组件结构：

```
lib/
├── database/          # SQLite 数据库创建、表结构迁移与 Raw Query
├── models/            # 实体模型（Medicine, Schedule, Reminder, Symptom等）
├── providers/         # ChangeNotifier 业务层逻辑（药品、日程、提醒、症状）
├── screens/
│   ├── home/          # 个人主页与标签解耦逻辑
│   │   ├── tabs/      # 拆解解耦后的 4 大子页面组件
│   │   │   ├── home_tab.dart        # 周打卡、低库存警报、时段用药卡片
│   │   │   ├── medicine_tab.dart    # 药品活性切换、删除确认弹窗
│   │   │   ├── stats_tab.dart       # 依从率计算、健康评估、服药日志
│   │   │   └── profile_tab.dart     # 快速入口列表、家属管理跳转
│   │   └── patient_home_screen.dart # 简洁的导航脚手架（<230行）
│   ├── schedule/      # 用药计划的灵活编辑表单
│   ├── symptom/       # 症状程度的评分及药理绑定
│   └── guardian/      # 家属绑定与数据监护
├── theme/             # Material 3 调色板与语义颜色（medTaken, medPending）
└── utils/             # Lunar 农历万年历算法转换工具
```

---

## 🚀 快速启动与构建

### 1. 克隆与环境准备
```bash
# 克隆至本地
git clone git@github.com:KonoyXu/medication-reminder.git
cd medication-reminder

# 补全依赖包
flutter pub get
```

### 2. 测试执行 (关键步骤)
由于集成测试中涉及异步数据库 FFI 多端并发连接处理，**强烈建议使用单线程顺序执行测试**：
```bash
# 保证 100% 成功率且无多连接死锁
flutter test --concurrency=1
```

### 3. 构建编译 (Windows 端 Android 打包)
若构建 APK 时报 `JAVA_HOME` 环境变量缺失错误，需在终端明确指定 JDK（例如内置 of JDK 17）：
```powershell
# PowerShell 环境下指定 Java 路径并编译
$env:JAVA_HOME="C:\Program Files\Java\jdk17"
$env:Path+=";C:\Program Files\Java\jdk17\bin"
flutter build apk --release
```
编译成功后的 APK 产物路径通常在：`build\app\outputs\flutter-apk\app-release.apk`

---

## 📄 开源许可证

本项目基于 [MIT](LICENSE) 许可证开源。