# 鸿蒙音乐播放器 - 完整文件索引

## 页面文件（Pages）- 4个

| 文件名 | 路径 | 描述 | 行数 | @Entry |
|--------|------|------|------|--------|
| Index.ets | `/entry/src/main/ets/pages/Index.ets` | 主页面（歌曲列表、播放列表、设置选项卡） | 859 | Yes |
| PlayerPage.ets | `/entry/src/main/ets/pages/PlayerPage.ets` | 全屏播放器详情页面 | 529 | Yes |
| SearchPage.ets | `/entry/src/main/ets/pages/SearchPage.ets` | 音乐搜索页面 | 150+ | Yes |
| SettingsPage.ets | `/entry/src/main/ets/pages/SettingsPage.ets` | 应用设置页面 | 150+ | Yes |

---

## 组件文件（Components）- 6个

| 文件名 | 路径 | 描述 | 高度 | 用途 |
|--------|------|------|------|------|
| MiniPlayer.ets | `/entry/src/main/ets/components/MiniPlayer.ets` | **核心迷你播放器** | 64px | 主页面底部播放控制 |
| PlayerControls.ets | `/entry/src/main/ets/components/PlayerControls.ets` | 播放器页面控制按钮组 | 动态 | PlayerPage中使用 |
| MusicItem.ets | `/entry/src/main/ets/components/MusicItem.ets` | 歌曲列表项 | 72px | Index歌曲列表 |
| SongItem.ets | `/entry/src/main/ets/components/SongItem.ets` | 备用歌曲列表项 | 64px | 备选列表使用 |
| PlayQueuePanel.ets | `/entry/src/main/ets/components/PlayQueuePanel.ets` | 播放队列底部弹窗 | 60%高 | 弹出式队列管理 |
| Index.ets | `/entry/src/main/ets/components/Index.ets` | 组件导出文件 | - | 统一导出 |

---

## 应用入口

| 文件名 | 路径 | 描述 | 关键方法 |
|--------|------|------|---------|
| EntryAbility.ets | `/entry/src/main/ets/entryability/EntryAbility.ets` | UIAbility应用主入口 | onCreate, onWindowStageCreate, onForeground, onBackground |

---

## 全局状态管理

| 文件名 | 路径 | 描述 | 关键字段 |
|--------|------|------|---------|
| GlobalPlayState.ets | `/entry/src/main/ets/common/GlobalPlayState.ets` | AppStorage全局播放状态管理 | CURRENT_SONG, IS_PLAYING, PLAY_MODE, CURRENT_POSITION, CURRENT_INDEX |

---

## 核心业务逻辑

| 文件名 | 路径 | 描述 | 关键类 |
|--------|------|------|--------|
| PlayController.ets | `/entry/src/main/ets/common/PlayController.ets` | 播放控制器（单例） | PlayController |
| PermissionManager.ets | `/entry/src/main/ets/common/PermissionManager.ets` | 权限管理器（单例） | PermissionManager |
| MockData.ets | `/entry/src/main/ets/common/MockData.ets` | 模拟数据工厂 | MockData |
| LazyDataSource.ets | `/entry/src/main/ets/common/LazyDataSource.ets` | LazyForEach数据源 | SongDataSource |

---

## 服务层（Service）- 9个

| 文件名 | 路径 | 描述 | 关键功能 |
|--------|------|------|---------|
| AudioPlayerService.ets | `/entry/src/main/ets/service/AudioPlayerService.ets` | 音频播放服务 | 播放、暂停、停止、进度控制 |
| PlayQueueService.ets | `/entry/src/main/ets/service/PlayQueueService.ets` | 播放队列管理 | 队列操作、切歌、播放模式 |
| MusicScanService.ets | `/entry/src/main/ets/service/MusicScanService.ets` | 音乐文件扫描 | 扫描媒体库、文件选择 |
| SleepTimerService.ets | `/entry/src/main/ets/service/SleepTimerService.ets` | 定时关闭服务 | 定时器管理 |
| MediaSessionManager.ets | `/entry/src/main/ets/service/MediaSessionManager.ets` | 媒体会话管理 | 系统媒体控制 |
| AudioFocusManager.ets | `/entry/src/main/ets/service/AudioFocusManager.ets` | 音频焦点管理 | 焦点争夺处理 |
| BackgroundTaskManager.ets | `/entry/src/main/ets/service/BackgroundTaskManager.ets` | 后台任务管理 | 后台播放 |
| PlaylistService.ets | `/entry/src/main/ets/service/PlaylistService.ets` | 播放列表服务 | 列表CRUD操作 |
| Index.ets | `/entry/src/main/ets/service/Index.ets` | 服务导出文件 | 统一导出 |

---

## 数据模型（Model）- 6个

| 文件名 | 路径 | 描述 | 关键属性 |
|--------|------|------|---------|
| Song.ets | `/entry/src/main/ets/model/Song.ets` | 歌曲数据模型 | id, title, artist, album, duration, path, albumArt |
| Playlist.ets | `/entry/src/main/ets/model/Playlist.ets` | 播放列表模型 | id, name, songIds, coverUri, createTime |
| PlayState.ets | `/entry/src/main/ets/model/PlayState.ets` | 播放状态枚举 | SEQUENCE, LOOP, SINGLE, SHUFFLE |
| Album.ets | `/entry/src/main/ets/model/Album.ets` | 专辑模型 | id, name, artist, coverUri |
| Artist.ets | `/entry/src/main/ets/model/Artist.ets` | 艺术家模型 | id, name, albums |
| Index.ets | `/entry/src/main/ets/model/Index.ets` | 模型导出文件 | 统一导出 |

---

## ViewModel层 - 4个

| 文件名 | 路径 | 描述 | 关键职责 |
|--------|------|------|---------|
| PlayerViewModel.ets | `/entry/src/main/ets/viewmodel/PlayerViewModel.ets` | 播放器ViewModel | 播放状态管理 |
| SongListViewModel.ets | `/entry/src/main/ets/viewmodel/SongListViewModel.ets` | 歌曲列表ViewModel | 列表数据管理 |
| PlaylistViewModel.ets | `/entry/src/main/ets/viewmodel/PlaylistViewModel.ets` | 播放列表ViewModel | 列表集合管理 |
| Index.ets | `/entry/src/main/ets/viewmodel/Index.ets` | ViewModel导出文件 | 统一导出 |

---

## 数据层

### 数据库（Database）- 3个

| 文件名 | 路径 | 描述 | 关键功能 |
|--------|------|------|---------|
| DatabaseHelper.ets | `/entry/src/main/ets/data/database/DatabaseHelper.ets` | 数据库初始化 | 表创建、连接管理 |
| SongDao.ets | `/entry/src/main/ets/data/database/SongDao.ets` | 歌曲DAO | CRUD操作 |
| PlaylistDao.ets | `/entry/src/main/ets/data/database/PlaylistDao.ets` | 播放列表DAO | CRUD操作 |

### 偏好设置（Preferences）- 1个

| 文件名 | 路径 | 描述 | 关键功能 |
|--------|------|------|---------|
| PreferencesManager.ets | `/entry/src/main/ets/data/preferences/PreferencesManager.ets` | 偏好设置管理 | 配置存取、搜索历史 |

### 仓储层（Repository）- 2个

| 文件名 | 路径 | 描述 | 关键功能 |
|--------|------|------|---------|
| SongRepository.ets | `/entry/src/main/ets/data/repository/SongRepository.ets` | 歌曲仓储 | 数据层抽象 |
| PlaylistRepository.ets | `/entry/src/main/ets/data/repository/PlaylistRepository.ets` | 播放列表仓储 | 数据层抽象 |

---

## 工具和常量

### 工具类（Utils）- 4个

| 文件名 | 路径 | 描述 | 关键方法 |
|--------|------|------|---------|
| TimeUtils.ets | `/entry/src/main/ets/common/utils/TimeUtils.ets` | 时间格式化工具 | formatDuration(), formatTime() |
| FileUtils.ets | `/entry/src/main/ets/common/utils/FileUtils.ets` | 文件操作工具 | 文件读写、路径处理 |
| Logger.ets | `/entry/src/main/ets/common/utils/Logger.ets` | 日志工具 | debug(), info(), error() |
| Index.ets | `/entry/src/main/ets/common/utils/Index.ets` | 工具导出文件 | 统一导出 |

### 常量（Constants）- 2个

| 文件名 | 路径 | 描述 | 关键常量 |
|--------|------|------|---------|
| AppConstants.ets | `/entry/src/main/ets/common/constants/AppConstants.ets` | 应用常量 | API_BASE_URL, TIMEOUT等 |
| Index.ets | `/entry/src/main/ets/common/constants/Index.ets` | 常量导出文件 | 统一导出 |

---

## 完整路径总结

### Pages目录 (4个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/
├── Index.ets
├── PlayerPage.ets
├── SearchPage.ets
└── SettingsPage.ets
```

### Components目录 (6个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/
├── MiniPlayer.ets (核心播放控制)
├── PlayerControls.ets
├── MusicItem.ets
├── SongItem.ets
├── PlayQueuePanel.ets (队列弹窗)
└── Index.ets
```

### Common目录 (9个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/
├── GlobalPlayState.ets (全局状态)
├── PlayController.ets (播放控制)
├── PermissionManager.ets
├── MockData.ets
├── LazyDataSource.ets
├── Index.ets
├── constants/
│   ├── AppConstants.ets
│   └── Index.ets
└── utils/
    ├── TimeUtils.ets
    ├── FileUtils.ets
    ├── Logger.ets
    └── Index.ets
```

### Service目录 (9个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/service/
├── AudioPlayerService.ets
├── PlayQueueService.ets
├── MusicScanService.ets
├── SleepTimerService.ets
├── MediaSessionManager.ets
├── AudioFocusManager.ets
├── BackgroundTaskManager.ets
├── PlaylistService.ets
└── Index.ets
```

### Model目录 (6个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/model/
├── Song.ets
├── Playlist.ets
├── PlayState.ets
├── Album.ets
├── Artist.ets
└── Index.ets
```

### ViewModel目录 (4个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/viewmodel/
├── PlayerViewModel.ets
├── SongListViewModel.ets
├── PlaylistViewModel.ets
└── Index.ets
```

### Data目录 (7个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/
├── Index.ets
├── database/
│   ├── DatabaseHelper.ets
│   ├── SongDao.ets
│   ├── PlaylistDao.ets
│   └── Index.ets
├── preferences/
│   ├── PreferencesManager.ets
│   └── Index.ets
└── repository/
    ├── SongRepository.ets
    ├── PlaylistRepository.ets
    └── Index.ets
```

### EntryAbility (1个文件)
```
/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/entryability/
└── EntryAbility.ets
```

---

## 文件统计

| 分类 | 数量 |
|------|------|
| Pages (页面) | 4 |
| Components (组件) | 6 |
| Services (服务) | 9 |
| Models (数据模型) | 6 |
| ViewModels | 4 |
| Database & Data | 7 |
| Common (通用) | 9 |
| EntryAbility | 1 |
| **总计** | **46个ETS文件** |

---

## 关键文件优先级

### 优先学习/修改 (必读)
1. `/entry/src/main/ets/pages/Index.ets` - 主页面入口
2. `/entry/src/main/ets/components/MiniPlayer.ets` - 核心播放控制
3. `/entry/src/main/ets/pages/PlayerPage.ets` - 播放详情
4. `/entry/src/main/ets/common/GlobalPlayState.ets` - 全局状态
5. `/entry/src/main/ets/entryability/EntryAbility.ets` - 应用入口

### 次要学习 (推荐)
6. `/entry/src/main/ets/components/PlayQueuePanel.ets` - 队列管理
7. `/entry/src/main/ets/service/AudioPlayerService.ets` - 播放服务
8. `/entry/src/main/ets/common/PlayController.ets` - 播放控制器
9. `/entry/src/main/ets/model/Song.ets` - 数据模型
10. `/entry/src/main/ets/pages/SearchPage.ets` - 搜索功能

---

最后更新：2025-12-22
