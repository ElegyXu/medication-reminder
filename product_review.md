# 「家庭用药管家」App 功能清单与逻辑梳理

> **产品经理视角 · 全量代码审查报告**
> 项目：`medication_reminder` v1.0.29+30
> 审查日期：2026-06-17

---

## 1. 项目结构总览

```
C:\tmp\med\
├── lib/
│   ├── main.dart                          # 应用入口、路由配置、Provider 注入
│   ├── database/
│   │   └── database_helper.dart           # SQLite 数据库单例（5表 + 3索引 + 统计）
│   ├── models/
│   │   ├── medicine.dart                  # 药品模型
│   │   ├── schedule.dart                  # 用药计划模型（含 ScheduleFrequency 枚举）
│   │   ├── reminder.dart                  # 服药提醒模型（含 ReminderStatus 枚举）
│   │   ├── symptom.dart                   # 症状日记模型
│   │   └── guardian_binding.dart          # 家属绑定模型（含 BindingStatus 枚举）
│   ├── providers/
│   │   ├── medicine_provider.dart         # 药品状态管理
│   │   ├── schedule_provider.dart         # 用药计划状态管理
│   │   ├── reminder_provider.dart         # 服药提醒状态管理
│   │   └── symptom_provider.dart          # 症状状态管理
│   ├── screens/
│   │   ├── home/
│   │   │   ├── patient_home_screen.dart   # 患者首页（5-Tab 主框架）
│   │   │   └── guardian_home_screen.dart  # 家属监护页面
│   │   ├── medicine/
│   │   │   └── medicine_form_screen.dart  # 药品新增/编辑表单
│   │   ├── schedule/
│   │   │   ├── schedule_form_screen.dart  # 用药计划表单（核心复杂度高）
│   │   │   └── schedule_list_screen.dart  # 用药计划列表（搜索/安全检测/药品卡片）
│   │   └── symptom/
│   │       └── symptom_diary_screen.dart  # 症状日记
│   ├── services/
│   │   └── notification_service.dart      # 本地通知服务（双通道 + Android 快捷操作）
│   ├── theme/
│   │   └── app_theme.dart                 # Material 3 主题（主色 #C41E3A）
│   ├── utils/
│   │   └── lunar_calendar.dart            # 农历计算（1900-2100）
│   └── widgets/
│       ├── async_content_wrapper.dart     # 异步四态包装器
│       └── reminder_bottom_sheet.dart     # 提醒操作底部弹窗
├── test/
│   ├── app_smoke_test.dart                # App 冒烟测试
│   ├── database/
│   │   ├── database_helper_test.dart      # 数据库 CRUD 全覆盖测试
│   │   └── database_edge_test.dart        # 数据库边界/混合/健壮性测试
│   ├── home_screen_layout_test.dart       # 首页布局测试
│   ├── lunar_calendar_test.dart           # 农历工具测试
│   ├── medicine_model_test.dart           # Medicine 模型测试
│   ├── reminder_model_test.dart           # Reminder 模型测试
│   ├── schedule_model_test.dart           # MedicationSchedule 模型测试
│   ├── models/
│   │   ├── extended_model_test.dart       # 模型边界覆盖
│   │   ├── guardian_binding_model_test.dart
│   │   ├── symptom_model_test.dart
│   │   └── models_full_test.dart          # 5 模型全量往返序列化测试
│   └── providers/
│       ├── providers_test.dart            # Provider 核心功能测试
│       └── provider_edge_test.dart        # Provider 边界与集成测试
└── pubspec.yaml                           # 依赖声明
```

**技术栈概要：**

| 层级 | 技术选型 |
|------|----------|
| 框架 | Flutter 3.x (SDK ^3.9.2) |
| 状态管理 | Provider (MultiProvider 注入 4 个 ChangeNotifier) |
| 路由 | GoRouter（单路由 `/` 指向 PatientHomeScreen） |
| 持久化 | sqflite（5 表 SQLite，单例模式） |
| 本地通知 | flutter_local_notifications（含时区支持） |
| 本地化 | intl（中文） |
| 测试 | flutter_test + sqflite_common_ffi（内存数据库） |

---

## 2. 页面清单

| # | 页面文件 | 职责说明 | 路由方式 |
|---|----------|----------|----------|
| 1 | `lib/screens/home/patient_home_screen.dart` | **患者首页**。1312 行核心页面，含 SliverAppBar（农历+问候语）+ 5 个 Tab（主页/用药计划/药品管理/服药统计/我的）。FAB 随 Tab 切换不同功能入口。内嵌用药进度卡片、周历、连续服药统计、时段分组药品卡片、健康风险评估、快捷入口、家属监护入口等。 | GoRouter `/` |
| 2 | `lib/screens/home/guardian_home_screen.dart` | **家属监护页面**。展示家属绑定列表，支持添加绑定（输入患者手机号/昵称）和删除绑定。本地版本直接生效（无服务端）。 | push / 内部路由 |
| 3 | `lib/screens/medicine/medicine_form_screen.dart` | **药品表单页**。新建/编辑药品，含名称、剂型、规格、备注、颜色选择。编辑模式携带已有药品数据。 | push |
| 4 | `lib/screens/schedule/schedule_form_screen.dart` | **用药计划表单页**。591 行高复杂度页面。选择关联药品（DropdownButtonFormField）、剂量、频率（SegmentedButton：每日/每周/每月/按需）、时间点（自定义 TimePickerSheet 滚轮选择器）、周/月日期选择器、PRN 配置（每日上限/最小间隔）、日期范围（起止日期）。支持编辑模式。 | push |
| 5 | `lib/screens/schedule/schedule_list_screen.dart` | **用药计划列表页**。480 行，含搜索栏、安全检测卡片（药物冲突提示）、药品计划卡片（频率标签/完成率进度条/时间标签/开关）、下次服药倒计时、左滑编辑/删除操作（flutter_slidable）。 | push |
| 6 | `lib/screens/symptom/symptom_diary_screen.dart` | **症状日记页**。217 行，支持添加症状记录（名称/严重程度 1-5 滑块+星级/关联药品选择/备注），列表展示含左滑删除。 | push |

### 2.1 PatientHomeScreen 五 Tab 详细拆解

PatientHomeScreen 是应用主框架，其内部 5 个 Tab 并非独立页面文件，而是在 `_buildPage` 方法中按 `_currentIndex` 条件渲染：

| Tab | 索引 | 图标 | 内容组件/逻辑 |
|-----|------|------|--------------|
| 主页 | 0 | `house` | SliverAppBar 头部（农历+随机问候语）、用药进度圆形卡片（今日应服/已服）、**周历**（横向日视图）、连续服药天数统计、**时段分组药品卡片**（上午/中午/下午/晚上）、空状态引导 |
| 用药计划 | 1 | `calendar_month` | 内嵌 `ScheduleListScreen` 组件（搜索栏 + 计划列表） |
| 药品管理 | 2 | `medication` | 药品列表（颜色圆点+名称+规格+状态开关）、空状态引导 |
| 服药统计 | 3 | `bar_chart` | 依从率统计、每日完成情况柱状图、**健康风险评估**（依从率分级+风险提示+建议）、连续服药天数 |
| 我的 | 4 | `person` | 用户信息区（头像+昵称）、快捷入口（症状日记/家属监护/用药提醒设置）、家属监护入口（跳转 GuardianHomeScreen） |

### 2.2 页面的完整用户交互流程

```
[应用启动]
    │
    ▼
[PatientHomeScreen] ─────────────────────────────────────────────────
    │                        │          │          │          │
    │ Tab0 主页               │Tab1      │Tab2      │Tab3      │Tab4 我的
    │                        │          │          │          │
    ├─ 查看今日用药卡片       │          │          │          │
    ├─ 点击药品卡片           │          │          │          │
    │  └─ ReminderBottomSheet │          │          │          │
    │     ├─ 确认用药 → take  │          │          │          │
    │     ├─ 延迟15分钟        │          │          │          │
    │     └─ 跳过本次 → skip  │          │          │          │
    │                        │          │          │          │
    │               [用药计划列表]    [药品列表]   [服药统计]     │
    ├─ FAB(+)               │          ├─ FAB(+)  │          ├─ 快捷入口
    │  └─ ScheduleForm      │          │  └─ MedForm        ├─ 症状日记
    │     (新建计划)         │          │                     │  └─ SymptomDiary
    │                        │          ├─ 点击药品           ├─ 家属监护
    │               ┌─ 搜索栏         │  └─ MedForm(编辑)    │  └─ GuardianHome
    │               ├─ 安全检测卡片   │                     │
    │               ├─ 计划卡片       ├─ 左滑/开关           │
    │               │  ├─ 开关切换    │  └─ toggleActive     │
    │               │  ├─ 点击编辑    │                     │
    │               │  │  └─ ScheduleForm(编辑模式)          │
    │               │  └─ 左滑删除    │                     │
    │               └─ ...            │                     │
    └──────────────────────────────────────────────────────────────
```

---

## 3. Provider 清单

### 3.1 MedicineProvider

| 属性 | 说明 |
|------|------|
| **文件** | `lib/providers/medicine_provider.dart` |
| **基类** | `ChangeNotifier` |
| **管理状态** | `List<Medicine> medicines`、`bool isLoading`、`String? errorMessage` |
| **派生属性** | `List<Medicine> activeMedicines`（过滤 `isActive == true`） |

| 方法 | 签名 | 说明 |
|------|------|------|
| `loadMedicines` | `Future<void> loadMedicines()` | 从数据库全量加载药品列表，按 `updatedAt` 降序排列 |
| `addMedicine` | `Future<void> addMedicine({required name, dosageForm, specification, notes, colorValue})` | 新建药品，自动生成 UUID，写入 DB 后刷新列表 |
| `updateMedicineData` | `Future<void> updateMedicineData(Medicine medicine)` | 更新药品全部字段到 DB 后刷新 |
| `toggleMedicineActive` | `Future<void> toggleMedicineActive(Medicine medicine)` | 切换 `isActive` 布尔值 |
| `removeMedicine` | `Future<void> removeMedicine(String id)` | 删除药品（DB 层 CASCADE 删除关联 schedules） |

---

### 3.2 ScheduleProvider

| 属性 | 说明 |
|------|------|
| **文件** | `lib/providers/schedule_provider.dart` |
| **基类** | `ChangeNotifier` |
| **管理状态** | `List<MedicationSchedule> schedules`、`bool isLoading`、`String? errorMessage` |
| **派生属性** | `List<MedicationSchedule> activeSchedules`（过滤 `isActive == true`） |

| 方法 | 签名 | 说明 |
|------|------|------|
| `loadSchedules` | `Future<void> loadSchedules()` | 从 DB 加载全部用药计划 |
| `addSchedule` | `Future<void> addSchedule({required medicineId, medicineName, dosage, frequency, timePoints, startDate, weekDays, monthDays, endDate, prnMaxDaily, prnMinIntervalMinutes})` | 创建用药计划（自动 UUID），写入 DB 后刷新 |
| `updateScheduleData` | `Future<void> updateScheduleData(MedicationSchedule schedule)` | 更新计划全部字段到 DB 后刷新 |
| `toggleScheduleActive` | `Future<void> toggleScheduleActive(MedicationSchedule schedule)` | 切换计划激活/停用状态 |
| `removeSchedule` | `Future<void> removeSchedule(String id)` | 删除指定计划 |

---

### 3.3 ReminderProvider

| 属性 | 说明 |
|------|------|
| **文件** | `lib/providers/reminder_provider.dart` |
| **基类** | `ChangeNotifier` |
| **管理状态** | `List<Reminder> todayReminders`、`bool isLoading`、`String? errorMessage` |

| 派生属性 | 类型 | 说明 |
|----------|------|------|
| `todayStats` | `Map<String, int>` | `{'total': N, 'taken': M}` 今日服药统计 |
| `todayAdherence` | `double` | 今日依从率 = taken / total（0.0 ~ 1.0） |
| `consecutiveDays` | `int` | 连续服药天数（从今天往回数连续有 taken 记录的天数） |

| 方法 | 签名 | 说明 |
|------|------|------|
| `loadTodayReminders` | `Future<void> loadTodayReminders()` | 加载今日提醒并计算统计/依从率/连续天数 |
| `generateTodayReminders` | `Future<void> generateTodayReminders(List<MedicationSchedule> schedules)` | 根据活跃计划生成本日提醒（防重复插入），写入 DB 并调度本地通知 |
| `takeMedicine` | `Future<void> takeMedicine(Reminder reminder)` | 标记已服：更新 DB → 更新内存列表 → 取消对应通知 |
| `skipMedicine` | `Future<void> skipMedicine(Reminder reminder)` | 标记跳过：status → skipped |
| `delayMedicine` | `Future<void> delayMedicine(Reminder reminder)` | 延迟 15 分钟：重设 scheduledTime +15min，重新调度通知 |
| `takePrnMedicine` | `Future<void> takePrnMedicine(String medicineId, String medicineName, String dosage)` | PRN 按需服药：手动插入一条 `taken` 状态提醒记录，检查每日上限与最小间隔 |

---

### 3.4 SymptomProvider

| 属性 | 说明 |
|------|------|
| **文件** | `lib/providers/symptom_provider.dart` |
| **基类** | `ChangeNotifier` |
| **管理状态** | `List<Symptom> symptoms`、`bool isLoading`、`String? errorMessage` |

| 方法 | 签名 | 说明 |
|------|------|------|
| `loadSymptoms` | `Future<void> loadSymptoms()` | 从 DB 加载全部症状记录（按 createdAt 降序） |
| `addSymptom` | `Future<void> addSymptom({required name, severity, notes, relatedMedicineId, relatedMedicineName})` | 添加症状记录 |
| `removeSymptom` | `Future<void> removeSymptom(String id)` | 删除指定症状记录 |

---

## 4. 数据模型

### 4.1 Medicine（药品）

| 字段 | Dart 类型 | 数据库列名 | 说明 |
|------|-----------|------------|------|
| `id` | `String` | `id` | UUID 主键 |
| `name` | `String` | `name` | 药品名称 |
| `dosageForm` | `String` | `dosage_form` | 剂型（片剂/胶囊/冲剂/注射液/颗粒剂等） |
| `specification` | `String` | `specification` | 规格（如 500mg、每袋10g×10袋） |
| `notes` | `String?` | `notes` | 备注（如"饭后服用"） |
| `colorValue` | `int` | `color_value` | 颜色值，默认 `0xFFC41E3A`（主题红） |
| `isActive` | `bool` | `is_active` | 是否启用，默认 `true` |
| `createdAt` | `DateTime` | `created_at` | 创建时间 |
| `updatedAt` | `DateTime` | `updated_at` | 最后更新时间 |

**方法**：`toMap()` / `Medicine.fromMap(map)` / `copyWith(...)`

**关系**：一对多 → `MedicationSchedule`（删除 Medicine 时 CASCADE 删除其所有 Schedule）

---

### 4.2 MedicationSchedule（用药计划）

| 字段 | Dart 类型 | 数据库列名 | 说明 |
|------|-----------|------------|------|
| `id` | `String` | `id` | UUID 主键 |
| `medicineId` | `String` | `medicine_id` | 关联药品 ID（外键） |
| `medicineName` | `String` | `medicine_name` | 冗余药品名（便于列表展示） |
| `dosage` | `String` | `dosage` | 剂量（如"1片"、"2粒"） |
| `frequency` | `ScheduleFrequency` | `frequency` | 频率枚举 |
| `timePoints` | `List<String>` | `time_points` | 时间点列表（逗号拼接存储，如 `08:00,20:00`） |
| `startDate` | `DateTime` | `start_date` | 开始日期 |
| `endDate` | `DateTime?` | `end_date` | 结束日期（可选） |
| `weekDays` | `List<int>?` | `week_days` | 星期几 [1=周一, 7=周日]（仅 weekly 模式使用） |
| `monthDays` | `List<int>?` | `month_days` | 每月几号（仅 monthly 模式使用） |
| `prnMaxDaily` | `int?` | `prn_max_daily` | PRN 每日最大次数 |
| `prnMinIntervalMinutes` | `int?` | `prn_min_interval_minutes` | PRN 每次最小间隔（分钟） |
| `isActive` | `bool` | `is_active` | 是否启用，默认 `true` |
| `createdAt` | `DateTime` | `created_at` | 创建时间 |
| `updatedAt` | `DateTime` | `updated_at` | 最后更新时间 |

**ScheduleFrequency 枚举**：

| 值 | 中文标签 | 说明 |
|----|----------|------|
| `daily` | 每日 | 每天固定时间点服药 |
| `weekly` | 每周 | 指定星期几服药 |
| `monthly` | 每月 | 指定每月几号服药 |
| `prn` | 按需 | 必要时服用（如止痛药），含上限/间隔约束 |

**派生属性**：`frequencyLabel` → 返回中文标签

---

### 4.3 Reminder（服药提醒）

| 字段 | Dart 类型 | 数据库列名 | 说明 |
|------|-----------|------------|------|
| `id` | `String` | `id` | UUID 主键 |
| `scheduleId` | `String` | `schedule_id` | 关联用药计划 ID |
| `medicineName` | `String` | `medicine_name` | 冗余药品名 |
| `dosage` | `String` | `dosage` | 剂量 |
| `scheduledTime` | `DateTime` | `scheduled_time` | 计划服药时间 |
| `status` | `ReminderStatus` | `status` | 状态枚举，默认 `pending` |
| `source` | `String?` | `source` | 操作来源（`notification` / `manual`） |
| `takenAt` | `DateTime?` | `taken_at` | 实际服药时间 |
| `createdAt` | `DateTime` | `created_at` | 创建时间 |

**ReminderStatus 枚举**：

| 值 | 中文标签 | 说明 |
|----|----------|------|
| `pending` | 待服 | 未操作 |
| `taken` | 已服 | 已确认服药 |
| `skipped` | 跳过 | 主动跳过本次 |
| `missed` | 漏服 | 超时未操作（由系统标记） |

**派生属性**：`statusLabel` → 返回中文标签

**方法**：`copyWith(status, source, takenAt)`

---

### 4.4 Symptom（症状日记）

| 字段 | Dart 类型 | 数据库列名 | 说明 |
|------|-----------|------------|------|
| `id` | `String` | `id` | UUID 主键 |
| `name` | `String` | `name` | 症状名称（头痛/发热/咳嗽等） |
| `severity` | `int` | `severity` | 严重程度 1-5 |
| `notes` | `String?` | `notes` | 备注描述 |
| `relatedMedicineId` | `String?` | `related_medicine_id` | 关联药品 ID（可选） |
| `relatedMedicineName` | `String?` | `related_medicine_name` | 关联药品名称（可选） |
| `createdAt` | `DateTime` | `created_at` | 记录时间 |

**派生属性**：`severityLabel` → `{1: '很轻', 2: '轻度', 3: '中度', 4: '较重', 5: '严重', 其他: '未知'}`

---

### 4.5 GuardianBinding（家属绑定）

| 字段 | Dart 类型 | 数据库列名 | 说明 |
|------|-----------|------------|------|
| `id` | `String` | `id` | UUID 主键 |
| `patientPhone` | `String` | `patient_phone` | 患者手机号 |
| `patientNickname` | `String` | `patient_nickname` | 患者昵称 |
| `guardianPhone` | `String` | `guardian_phone` | 家属手机号 |
| `status` | `BindingStatus` | `status` | 绑定状态枚举，默认 `active` |
| `createdAt` | `DateTime` | `created_at` | 创建时间 |
| `updatedAt` | `DateTime` | `updated_at` | 更新时间 |

**BindingStatus 枚举**：

| 值 | 中文标签 |
|----|----------|
| `active` | 已绑定 |
| `pending` | 待确认 |
| `rejected` | 已拒绝 |
| `revoked` | 已解除 |

---

### 4.6 数据库表关系图

```
medicines (1) ────< (N) schedules (1) ────< (N) reminders
                      │
symptoms ─────────────┘ (可选关联 medicineId)
guardian_bindings (独立表)
```

**级联规则**：删除 `medicine` → CASCADE 删除其所有 `schedules`；删除 `schedule` 时不自动删除 `reminders`。

**索引**：
- `idx_reminders_schedule_id` ON reminders(schedule_id)
- `idx_reminders_status` ON reminders(status)
- `idx_reminders_scheduled_time` ON reminders(scheduled_time)

---

## 5. 服务层

### 5.1 NotificationService

| 属性 | 说明 |
|------|------|
| **文件** | `lib/services/notification_service.dart` |
| **模式** | 单例 |
| **依赖** | `flutter_local_notifications` + `timezone` |

**双通知通道**：

| 通道 ID | 通道名 | 重要性 | 用途 |
|---------|--------|--------|------|
| `medication_reminder` | 用药提醒 | HIGH | 按时服药提醒（含 Android 快捷操作按钮） |
| `medication_missed` | 漏服告警 | MAX | 超时未服药告警 |

**核心方法**：

| 方法 | 说明 |
|------|------|
| `init()` | 初始化通知插件，创建两个 Android 通知通道 |
| `scheduleReminder(...)` | 排程一条用药提醒通知（`zonedSchedule`），含 "已服药" / "跳过" 两个 Android NotificationAction，payload 携带 reminder_id |
| `showMissedAlert(...)` | 立即发送漏服告警通知 |
| `cancelNotification(int id)` | 取消指定通知 |
| `cancelAll()` | 取消所有通知 |
| `getActiveNotifications()` | 获取当前活跃通知列表 |

**Android 快捷操作机制**：`scheduleReminder` 创建的 Android 通知自带两个按钮 —— `take_{reminderId}`（已服药）和 `skip_{reminderId}`（跳过），用户可在通知栏直接操作而无需进入 App。

---

## 6. 工具与组件

| 文件 | 类型 | 说明 |
|------|------|------|
| `utils/lunar_calendar.dart` | 工具类 | 农历日期计算，基于 1900-2100 年的农历数据数组，`getLunarDate(DateTime)` 返回形如 `乙巳年五月初一` 的干支纪年+农历月日 |
| `widgets/async_content_wrapper.dart` | UI 组件 | 通用异步内容包装器，统一处理 `loading` / `empty` / `error` / `content` 四态 |
| `widgets/reminder_bottom_sheet.dart` | UI 组件 | 药品提醒操作底部弹窗，展示药品名称+剂量，三个操作按钮：「确认用药」（全宽主按钮，橙色 #FF6B35）、「延迟 15 分钟」、「跳过本次」（并排次要按钮） |
| `theme/app_theme.dart` | 主题 | Material 3 全局主题，主色 `0xFFC41E3A`（人民币红），完整定义了 AppBar / Card / FAB / NavigationBar / InputDecoration / ElevatedButton 等组件的样式 |

---

## 7. 现有测试用例清单

### 7.1 测试文件总览

| # | 测试文件 | 所属模块 | 测试数量（group | test） |
|---|----------|----------|------------------|
| 1 | `test/app_smoke_test.dart` | App 冒烟 | 1 group, 2 tests |
| 2 | `test/database/database_helper_test.dart` | 数据库 | 7 groups, 38 tests |
| 3 | `test/database/database_edge_test.dart` | 数据库边界 | 5 groups, 20 tests |
| 4 | `test/home_screen_layout_test.dart` | UI 布局 | 1 group, 2 tests |
| 5 | `test/lunar_calendar_test.dart` | 农历工具 | 1 group, 3 tests |
| 6 | `test/medicine_model_test.dart` | 模型 | 1 group, 4 tests |
| 7 | `test/reminder_model_test.dart` | 模型 | 1 group, 4 tests |
| 8 | `test/schedule_model_test.dart` | 模型 | 1 group, 5 tests |
| 9 | `test/models/extended_model_test.dart` | 模型边界 | 3 groups, 13 tests |
| 10 | `test/models/guardian_binding_model_test.dart` | 模型 | 1 group, 4 tests |
| 11 | `test/models/symptom_model_test.dart` | 模型 | 1 group, 5 tests |
| 12 | `test/models/models_full_test.dart` | 模型全量 | 5 groups, 36 tests |
| 13 | `test/providers/providers_test.dart` | Provider | 3 groups, 23 tests |
| 14 | `test/providers/provider_edge_test.dart` | Provider边界 | 4 groups, 24 tests |
| **合计** | | | **15 文件, 34 groups, ~183 tests** |

### 7.2 测试覆盖详情

#### A. App 冒烟测试 (`app_smoke_test.dart`)
- PatientHomeScreen 渲染：验证 NavigationBar 和 5 个 Tab 文字标签
- Tab 切换：点击「用药计划」切换到 Tab1

#### B. 数据库 CRUD 测试 (`database_helper_test.dart`)
**药品 CRUD (8 tests)**：插入查询、按 ID 查询、不存在的 ID 返回 null、按激活状态过滤、查询全部、更新、级联删除关联计划、空列表、重复 ID(replace)、按 updatedAt 降序排列

**用药计划 CRUD (9 tests)**：插入查询、按激活状态过滤、更新、删除、每周频率+weekDays、每月频率+monthDays、PRN+上限/间隔、含结束日期、空列表

**服药提醒 CRUD (9 tests)**：插入单条、批量插入、按状态过滤、按时间范围过滤、limit 参数、更新为已服、更新为跳过、按时序排列、空列表

**症状 CRUD (4 tests)**：插入查询、limit 限制、按时间降序排列、删除

**家属绑定 CRUD (4 tests)**：插入查询、按状态过滤、更新状态、删除

**统计数据 (4 tests)**：getTodayStats 无数据为 0、正确统计今日、getConsecutiveDays 无记录为 0/单天为 1/连续 3 天/有间断仅 1 天

**边界用例 (7 tests)**：特殊字符药品名、备注为空、多时间点计划、症状严重度边界值 1/5、所有绑定状态枚举、删除不存在记录不抛异常、批量插入空列表

#### C. 数据库边界测试 (`database_edge_test.dart`)
**模型边界与组合 (7 tests)**：copyWith 不传参相等、4 个枚举值验证、severityLabel 边界、相等性判断、copyWith 保持 scheduledTime

**数据库复杂查询 (5 tests)**：按 scheduleId 过滤提醒、100 条批量插入、limit 参数验证、跨表关联 CASCADE 删除、getTodayStats 区分今昨

**混合内容测试 (3 tests)**：多药品多计划混合、症状关联已删除药品、绑定所有状态持久化

**健壮性 (6 tests)**：空库查询不崩溃、toMap 字段完整性验证（2 个）、症状时间排序、仅昨天有记录连续天数、PRN 手动触发

#### D. UI 布局测试 (`home_screen_layout_test.dart`)
- CustomScrollView + SliverAppBar 结构（pinned/floating/expandedHeight/backgroundColor）
- SliverPadding 的 padding 值
- NavigationBar 5 个 destinations 的 label
- FlexibleSpaceBar 渐变色验证（3 色渐变）

#### E. 模型测试覆盖总览

| 模型 | 测试覆盖点 |
|------|-----------|
| **Medicine** | toMap/fromMap 往返、isActive bool↔int 转换、notes 空值、copyWith 部分/全字段、默认值（isActive=true, colorValue=0xFFC41E3A）、中文规格、非活动药品序列化 |
| **MedicationSchedule** | toMap/fromMap 往返、4 种频率枚举序列化、timePoints 逗号拼接、weekDays/monthDays 的 List↔String、endDate 空值处理、PRN 字段、frequencyLabel 中文 |
| **Reminder** | toMap/fromMap 往返、4 种状态中文标签、taken/skipped/missed 状态更新、source/takenAt 可空、默认状态 pending、copyWith 部分更新 |
| **Symptom** | toMap/fromMap 往返、severity 1-5 中文标签、severity 0/6 非法值返回"未知"、关联药品空值、notes 空值 |
| **GuardianBinding** | toMap/fromMap 往返、4 种状态中文标签、默认状态 active |

#### F. Provider 测试覆盖总览

| Provider | 测试覆盖点 |
|----------|-----------|
| **MedicineProvider** | 初始状态空、添加药品、多药品添加、含备注添加、更新药品信息、切换激活状态、删除药品、loadMedicines 刷新、activeMedicines 过滤、自定义颜色、并发添加、删除后重加同名、两次切换还原、空列表 activeMedicines、isLoading 状态 |
| **ScheduleProvider** | 初始状态空、添加 daily/weekly/monthly/PRN 四种计划、切换激活、删除、更新、activeSchedules 过滤、loadSchedules 刷新、含结束日期、PRN 空时间点 |
| **ReminderProvider** | 初始状态、无数据依从率 0%、loadTodayReminders 正常、todayStats 默认值、无提醒连续天数 0、重复生成不重复插入 |
| **跨 Provider 集成** | 完整流程（添加药品→创建计划→生成提醒）、生成后打卡、跳过服药、重复生成幂等、停用计划不生成提醒、加载幂等、多时间点全生成、takeMedicine/skipMedicine 状态变更 |

---

## 8. 用户交互流程（完整路径）

### 8.1 首次使用路径
```
启动 App → PatientHomeScreen(Tab0 主页，空状态引导)
  │
  ├─ 第1步：添加药品
  │   点击 FAB → MedicineFormScreen → 填写名称/剂型/规格/备注 → 保存 → 返回
  │
  ├─ 第2步：创建用药计划
  │   点击 FAB(用药计划Tab) → ScheduleFormScreen
  │   → 选择关联药品 → 输入剂量
  │   → 选择频率(每日/每周/每月/按需)
  │   → 设置时间点(TimePickerSheet)
  │   → (可选)周日期/月日期/PRN上限
  │   → 设置起止日期 → 保存
  │
  └─ 第3步：开始服药
       系统自动生成今日提醒 + 本地通知
       查看主页 → 点击药品卡片 → ReminderBottomSheet → 确认/延迟/跳过
```

### 8.2 日常使用路径
```
打开 App → PatientHomeScreen(Tab0 主页)
  │
  ├─ 查看今日进度（圆形进度卡片）
  ├─ 点击时段药品卡片 → ReminderBottomSheet 操作
  ├─ 滑动周历查看历史
  │
  ├─ Tab1 用药计划 → 查看/搜索/编辑/启停计划
  ├─ Tab2 药品管理 → 添加/编辑/启停/删除药品
  ├─ Tab3 服药统计 → 查看依从率/连续天数/健康风险评估
  └─ Tab4 我的 → 症状日记 / 家属监护 / 设置
```

### 8.3 通知交互路径
```
本地通知弹出（用药提醒）
  │
  ├─ 点击通知 → 进入 App（主页）
  ├─ 通知栏按钮「已服药」→ takeMedicine（无需进入 App）
  └─ 通知栏按钮「跳过」  → skipMedicine（无需进入 App）

漏服告警
  └─ 超时未操作 → showMissedAlert（最高优先级通知）
```

### 8.4 家属监护路径
```
Tab4 我的 → 点击「家属监护」→ GuardianHomeScreen
  │
  ├─ 查看已绑定家属列表（状态标签：已绑定/待确认/已拒绝/已解除）
  ├─ 添加绑定 → 输入患者手机号+昵称 → 保存（本地直接生效）
  └─ 删除绑定 → 确认删除
```

### 8.5 症状日记路径
```
Tab4 我的 → 点击「症状日记」→ SymptomDiaryScreen
  │
  ├─ 查看历史症状列表（按时间降序）
  ├─ 添加症状 → 名称 + 严重程度(1-5滑块+星级) + 关联药品 + 备注 → 保存
  └─ 左滑删除历史症状
```

---

## 9. 架构总结

### 9.1 当前架构特征

| 维度 | 现状 |
|------|------|
| **路由** | 极简 —— GoRouter 仅 1 条路由，其余页面通过 Navigator.push 跳转 |
| **状态管理** | 标准 Provider —— 4 个 ChangeNotifier，MultiProvider 在 main.dart 注入 |
| **数据层** | sqflite 本地数据库，单例 DatabaseHelper，5 表 + CRUD + 统计查询 |
| **通知** | flutter_local_notifications 双通道，时区感知，Android 快捷操作 |
| **UI 框架** | Material 3，主题化（AppTheme），组件化（AsyncContentWrapper） |
| **本地化** | intl 中文 |

### 9.2 关键设计决策

1. **药品-计划-提醒三层模型**：药品 ← 计划 ← 提醒，数据冗余 `medicineName` 到 plan 和 reminder 层以减少 JOIN 查询
2. **每日提醒预生成**：`generateTodayReminders` 在当日首次加载时根据活跃计划生成全部提醒，避免实时计算
3. **PRN 与定时分离**：PRN 按需服药走 `takePrnMedicine` 独立通道，含每日上限和最小间隔双重约束
4. **通知含业务 payload**：NotificationAction ID 嵌入 `reminderId`，通知栏操作可直接触发状态变更
5. **防重复生成**：`generateTodayReminders` 通过检查当日是否已有同一 schedule 的 pending 提醒来防重

### 9.3 未覆盖/待完善的能力

| 能力 | 当前状态 |
|------|----------|
| 药物相互作用/安全检测 | UI 入口已就位（ScheduleListScreen 安全检测卡片），但后端逻辑待完善 |
| 家属监护远程同步 | 仅本地数据，无远程绑定/数据同步逻辑 |
| 数据备份/导出 | 未实现 |
| 多用户/账号系统 | 未实现（当前单用户本地 App） |
| 用药提醒自定义铃声/振动 | 已设 importance/priority，未开放用户自定义 |
| 暗黑模式 | 未实现（仅 Material 3 亮色主题） |

---

*报告生成完毕。本报告基于 `C:\tmp\med` 项目 `lib/` 和 `test/` 目录下全部源代码文件的全文审查。*
