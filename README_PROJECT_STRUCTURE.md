# 鸿蒙音乐播放器项目 - 文档索引

## 快速开始

### 推荐阅读顺序

1. **PROJECT_SUMMARY.md** (首先阅读)
   - 项目全景概览
   - 5 层架构总结
   - 4 个核心服务简介
   - 关键功能特性列表
   - 代码质量评估

2. **harmony_music_player_structure.md** (深入了解)
   - 16 个章节的详细分析
   - 完整的目录树结构
   - 每个模块的详细说明
   - 数据模型定义
   - 架构层次图

3. **harmony_quick_reference.md** (快速查询)
   - 所有关键文件的绝对路径
   - 核心类的接口签名
   - 枚举和常量定义
   - 快速导航命令

---

## 文档内容一览

### PROJECT_SUMMARY.md (12 KB)

**主要内容**:
- 项目基本信息
- 5 层架构图
- 5 个关键配置文件详解
- 4 个核心服务类
- 权限系统详解
- 3 个主要页面
- 5 个可复用组件
- 5 个核心数据模型
- 初始化流程图
- 12 个已实现的功能特性
- 47 个源文件统计
- 快速查询表
- 代码质量评估

**适合**: 想要快速了解项目整体结构

---

### harmony_music_player_structure.md (23 KB)

**包含 16 个章节**:

1. 项目整体目录结构 - 完整的树形结构
2. Module.json5 配置文件详解 - 权限和入口配置
3. 现有的音频播放相关代码 - 5 个核心服务
4. 现有的权限配置 - 5 个权限详解
5. 入口文件和主要页面组件
6. 数据模型
7. 数据层架构 - 数据库、偏好、仓库
8. 状态管理
9. ViewModel 层
10. 公共工具和常量
11. 资源文件结构
12. 编译和构建配置
13. 完整的源文件列表
14. 架构层次总结
15. 关键特性
16. 核心权限清单

**适合**: 想要深入理解每个模块的设计

---

### harmony_quick_reference.md (11 KB)

**快速查询表**:

1. 配置文件路径表
2. 入口和核心文件表
3. 主要页面路径表
4. 主要组件路径表
5. 数据模型路径表
6. 数据访问层路径表
7. 工具和常量路径表
8. 资源文件路径表

**核心接口签名**:
- AudioPlayerService 的 19 个公开方法
- PlayController 的关键方法
- PermissionManager 的权限方法
- MusicScanService 的扫描方法
- GlobalPlayState 的状态方法
- PreferencesManager 的设置方法

**快速查询**:
- 4 种播放模式枚举
- 6 种播放状态枚举
- 6 个全局状态键
- 6 种支持的音频格式
- 5 个关键权限
- 初始化流程图
- 修改清单 (各种场景)
- 快速导航命令

**适合**: 需要快速找到某个文件或接口

---

## 项目结构速览

### 应用架构 (5 层)

```
表现层 (3 pages + 5 components)
       ↓ @StorageLink
全局状态 (AppStorage - 6 个状态键)
       ↓
业务逻辑层 (PlayController + 3 ViewModels)
       ↓
服务层 (4 个核心服务)
    - AudioPlayerService (使用 AVPlayer)
    - MusicScanService (文件扫描)
    - PlayQueueService (队列管理)
    - PlaylistService (列表管理)
       ↓
数据层 (Repository)
       ↓
数据访问层 (DAO + Preferences)
```

### 关键文件位置

**配置文件**:
- `/AppScope/app.json5` - 应用全局配置
- `/entry/src/main/module.json5` - 模块和权限配置
- `/entry/build-profile.json5` - 编译配置

**核心服务**:
- `/entry/src/main/ets/service/AudioPlayerService.ets` - 播放引擎
- `/entry/src/main/ets/service/MusicScanService.ets` - 音乐扫描
- `/entry/src/main/ets/common/PlayController.ets` - 播放控制
- `/entry/src/main/ets/common/GlobalPlayState.ets` - 全局状态

**UI**:
- `/entry/src/main/ets/pages/Index.ets` - 主页
- `/entry/src/main/ets/pages/PlayerPage.ets` - 播放器
- `/entry/src/main/ets/pages/SearchPage.ets` - 搜索页

---

## 关键特性速查

### 播放功能
- 播放/暂停/停止
- 快进快退 (seekTo)
- 上一首/下一首
- 4 种播放模式切换
- 进度显示和控制

### 扫描功能
- 支持 6 种音频格式 (mp3, flac, wav, aac, ogg, m4a)
- 文件选择器导入
- 数据库存储
- 进度回调

### 列表功能
- 歌曲列表显示
- 播放列表管理
- 播放队列
- 搜索功能

### 数据功能
- 数据库存储 (RDB)
- 偏好设置保存
- 播放历史记录

### 权限功能
- 5 个权限管理
- 运行时权限请求
- 权限兼容性处理

---

## 代码统计

### 源文件数量
- 总计: 47 个 .ets 文件
- 配置文件: 11 个 .json5 文件
- 资源文件: 20+ 图标 + 多个资源 JSON

### 代码量估算
- 入口类: 90 行 (EntryAbility.ets)
- 核心服务: ~2000 行
  - AudioPlayerService: 467 行
  - MusicScanService: 300+ 行
  - PlayQueueService: 370+ 行
  - PlaylistService: ~150 行
- 页面: ~1000 行
- 数据层: ~800 行
- 其他: ~2000 行

**总计**: 约 7000 行代码

---

## 设计模式

1. **单例模式**: 所有服务类和管理类都使用单例
2. **DAO 模式**: 数据访问层使用 DAO 模式
3. **Repository 模式**: 业务逻辑使用 Repository 模式
4. **观察者模式**: 播放事件监听
5. **MVC/MVVM**: 结合 @Component 和 @StorageLink

---

## 使用指南

### 查询播放逻辑
1. 打开 PROJECT_SUMMARY.md 的"四、4 个核心服务类"部分
2. 或查看 harmony_quick_reference.md 中的"AudioPlayerService 关键接口"
3. 跳转到 `/entry/src/main/ets/service/AudioPlayerService.ets` 查看实现

### 查询权限相关
1. 打开 PROJECT_SUMMARY.md 的"五、权限系统详解"部分
2. 查看 harmony_music_player_structure.md 的"四、现有的权限配置"
3. 查看 `/entry/src/main/module.json5` 的权限声明
4. 查看 `/entry/src/main/ets/common/PermissionManager.ets` 的实现

### 查询 UI 组件
1. 打开 PROJECT_SUMMARY.md 的"七、5 个主要可复用组件"部分
2. 查看对应的组件文件在 `/entry/src/main/ets/components/` 下

### 查询数据模型
1. 打开 PROJECT_SUMMARY.md 的"八、数据模型 (5 个核心模型)"部分
2. 查看模型文件在 `/entry/src/main/ets/model/` 下
3. 查看数据访问在 `/entry/src/main/ets/data/` 下

### 修改某个功能
1. 在 harmony_quick_reference.md 的"文件修改清单"中找到对应文件
2. 用绝对路径找到文件
3. 查看 harmony_music_player_structure.md 了解该模块的设计

---

## 常见问题

### Q: 如何添加新的播放模式?
A: 修改 `/entry/src/main/ets/model/PlayState.ets` 中的 PlayMode 枚举，然后在 `/entry/src/main/ets/service/AudioPlayerService.ets` 中的 `handlePlayComplete()` 方法添加处理逻辑。

### Q: 如何支持更多的音频格式?
A: 修改 `/entry/src/main/ets/service/MusicScanService.ets` 中的 `SUPPORTED_AUDIO_EXTENSIONS` 常量，然后在 `MimeTypeMap` 类中添加新格式的映射。

### Q: 如何修改权限?
A: 
1. 修改 `/entry/src/main/module.json5` 中的 `requestPermissions` 数组
2. 在 `/entry/src/main/ets/common/PermissionManager.ets` 中添加对应的权限请求方法

### Q: 如何添加新的 UI 页面?
A: 
1. 在 `/entry/src/main/ets/pages/` 中创建新的 .ets 文件
2. 在 `/entry/src/main/resources/base/profile/main_pages.json` 中添加页面路由
3. 使用 router 进行页面导航

### Q: 全局状态是如何工作的?
A: 使用 AppStorage (@StorageLink) 进行状态管理。所有状态都定义在 PlayStateKeys 中，UI 组件可以直接绑定这些状态键实现双向数据绑定。

---

## 下一步建议

### 功能扩展
1. 添加歌词显示功能
2. 实现播放评分系统
3. 支持在线音乐流
4. 添加播放统计分析

### 性能优化
1. 实现歌曲列表虚拟滚动
2. 优化数据库查询
3. 缓存专辑图片

### UI 改进
1. 实现深色模式
2. 添加主题切换
3. 改进动画效果

### 代码重构
1. 提取公共组件
2. 添加单元测试
3. 编写集成测试
4. 生成 API 文档

---

## 文档维护

这些文档是通过全项目探索生成的，包含：

- 所有 47 个源文件的分析
- 所有配置文件的解读
- 完整的架构设计说明
- 关键接口的方法签名
- 快速查询表

**最后更新**: 2025-12-19

---

## 快速导航

| 需求 | 文档 | 章节 |
|-----|------|------|
| 项目全景 | PROJECT_SUMMARY.md | 第一部分 |
| 架构详解 | harmony_music_player_structure.md | 第一、二章 |
| 权限配置 | harmony_music_player_structure.md | 第四章 |
| 快速查询 | harmony_quick_reference.md | 全部 |
| 代码质量 | PROJECT_SUMMARY.md | 第十五部分 |
| 初始化流程 | PROJECT_SUMMARY.md | 第十部分 |
| 数据模型 | harmony_music_player_structure.md | 第六章 |
| 服务层 | PROJECT_SUMMARY.md | 第四部分 |
| UI 组件 | harmony_music_player_structure.md | 第五章 |
| 修改指南 | harmony_quick_reference.md | 文件修改清单 |

---

**所有文档都保存在项目根目录中，可以离线查阅。**

