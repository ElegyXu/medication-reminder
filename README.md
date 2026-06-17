# 💊 药品提醒管家

一个基于 Flutter 的 Material Design 3 药品服用提醒应用，帮助患者按时服药，支持家属监护。

## 功能特性

- **药品管理** — 添加、编辑、删除药品，支持剂量、库存、有效期管理
- **用药计划** — 按天/周/月/按需频率制定服药计划，多时间点灵活配置
- **智能提醒** — 到点弹窗提醒，支持确认用药、延迟 15 分钟、跳过本次
- **服药统计** — 按日/周/月统计服药记录，追踪连续用药天数
- **症状日记** — 记录每日症状及严重程度，关联药品追踪药效
- **家属监护** — 绑定患者账号，远程查看服药状态
- **Material Design 3** — 全局 M3 主题，自动适配深色模式

## 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Flutter 3.x / Dart |
| 状态管理 | Provider |
| 本地存储 | SQLite (sqflite) |
| UI | Material Design 3 (useMaterial3: true) |
| 平台 | Android |

## 项目结构

```
lib/
├── database/          # 数据库定义与操作
├── models/            # 数据模型
├── providers/         # Provider 状态管理
├── screens/
│   ├── home/          # 主页（五大标签页）
│   ├── schedule/      # 用药计划
│   ├── symptom/       # 症状日记
│   └── guardian/      # 家属监护
├── theme/             # M3 主题配置
└── widgets/           # 可复用组件
```

## 快速开始

```bash
# 克隆仓库
git clone git@github.com:ElegyXu/medication-reminder.git

# 安装依赖
cd medication-reminder
flutter pub get

# 运行测试
flutter test

# 调试运行
flutter run

# 构建 APK
flutter build apk --release
```

## 截图

> 待补充

## License

MIT