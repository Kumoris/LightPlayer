# 鸿蒙音乐播放器 - 关键文件快速参考

## 绝对路径速查表

### 配置文件
| 文件名 | 路径 | 用途 |
|------|------|------|
| app.json5 | `/Users/lzh/DevEcoStudioProjects/MyApplication/AppScope/app.json5` | 应用全局配置 |
| module.json5 | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/module.json5` | 模块配置（权限、入口） |
| build-profile.json5 | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/build-profile.json5` | 编译配置 |
| oh-package.json5 | `/Users/lzh/DevEcoStudioProjects/MyApplication/oh-package.json5` | 项目包配置 |

### 入口和核心文件
| 文件名 | 路径 | 功能 |
|------|------|------|
| EntryAbility.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/entryability/EntryAbility.ets` | 应用入口点 |
| AudioPlayerService.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/service/AudioPlayerService.ets` | 核心播放引擎 |
| PlayController.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/PlayController.ets` | 播放控制器 |
| GlobalPlayState.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/GlobalPlayState.ets` | 全局状态管理 |
| PermissionManager.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/PermissionManager.ets` | 权限管理 |
| PreferencesManager.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/preferences/PreferencesManager.ets` | 偏好设置管理 |
| MusicScanService.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/service/MusicScanService.ets` | 音乐扫描服务 |

### 主要页面
| 文件名 | 路径 | 功能 |
|------|------|------|
| Index.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/Index.ets` | 主页/歌曲列表 |
| PlayerPage.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/PlayerPage.ets` | 播放器页面 |
| SearchPage.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/SearchPage.ets` | 搜索页面 |

### 主要组件
| 文件名 | 路径 | 用途 |
|------|------|------|
| MiniPlayer.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/MiniPlayer.ets` | 迷你播放器 |
| PlayQueuePanel.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/PlayQueuePanel.ets` | 播放队列弹窗 |
| MusicItem.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/MusicItem.ets` | 歌曲列表项 |
| PlayerControls.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/PlayerControls.ets` | 播放控制按钮 |

### 数据模型
| 文件名 | 路径 | 模型 |
|------|------|------|
| Song.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/model/Song.ets` | 歌曲数据模型 |
| PlayState.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/model/PlayState.ets` | 播放状态/模式枚举 |
| Playlist.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/model/Playlist.ets` | 播放列表模型 |

### 数据访问层
| 文件名 | 路径 | 功能 |
|------|------|------|
| DatabaseHelper.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/database/DatabaseHelper.ets` | 数据库初始化 |
| SongDao.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/database/SongDao.ets` | 歌曲 DAO |
| PlaylistDao.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/database/PlaylistDao.ets` | 播放列表 DAO |
| SongRepository.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/repository/SongRepository.ets` | 歌曲仓库 |
| PlaylistRepository.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/repository/PlaylistRepository.ets` | 播放列表仓库 |

### 工具和常量
| 文件名 | 路径 | 功能 |
|------|------|------|
| AppConstants.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/constants/AppConstants.ets` | 应用常量 |
| FileUtils.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/utils/FileUtils.ets` | 文件工具 |
| TimeUtils.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/utils/TimeUtils.ets` | 时间工具 |
| Logger.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/utils/Logger.ets` | 日志工具 |
| MockData.ets | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/MockData.ets` | 模拟数据 |

### 资源文件
| 文件名 | 路径 | 用途 |
|------|------|------|
| main_pages.json | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/resources/base/profile/main_pages.json` | 页面路由配置 |
| string.json | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/resources/base/element/string.json` | 字符串资源 |
| color.json | `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/resources/base/element/color.json` | 颜色定义 |

---

## 核心类和接口速查

### AudioPlayerService 关键接口
```typescript
class AudioPlayerService {
  static getInstance(): AudioPlayerService
  async initialize(): Promise<boolean>
  async play(song: Song): Promise<boolean>
  async start(): Promise<void>
  async pause(): Promise<void>
  async stop(): Promise<void>
  async seekTo(position: number): Promise<void>
  async playNext(): Promise<void>
  async playPrevious(): Promise<void>
  async setPlayMode(mode: PlayMode): Promise<void>
  async togglePlayMode(): Promise<PlayMode>
  setPlaylist(songs: Song[], startIndex?: number): void
  getPlaylist(): Song[]
  getCurrentSong(): Song | null
  getPlayState(): PlayState
  addListener(listener: PlayerEventListener): void
  removeListener(listener: PlayerEventListener): void
  async release(): Promise<void>
}
```

### PlayController 关键接口
```typescript
class PlayController implements PlayerEventListener {
  static getInstance(): PlayController
  initialize(): void
  async playSong(song: Song, index: number, playlist?: Song[]): Promise<boolean>
  async togglePlayPause(): Promise<void>
  async playNext(): Promise<void>
  async playPrevious(): Promise<void>
  async togglePlayMode(): Promise<PlayMode>
  release(): void
}
```

### PermissionManager 关键接口
```typescript
class PermissionManager {
  static getInstance(): PermissionManager
  async checkPermission(permission: Permissions): Promise<boolean>
  async requestPermission(context: common.UIAbilityContext, permission: Permissions): Promise<boolean>
  async requestPermissions(context: common.UIAbilityContext, permissions: Permissions[]): Promise<PermissionResult>
  async requestMusicPlayerPermissions(context: common.UIAbilityContext): Promise<PermissionResult>
}
```

### MusicScanService 关键接口
```typescript
class MusicScanService {
  static getInstance(): MusicScanService
  setContext(context: common.UIAbilityContext): void
  async selectAudioFiles(context: common.UIAbilityContext, callback?: ScanProgressCallback): Promise<Song[]>
  async loadSongsFromDatabase(): Promise<Song[]>
  async scanMusicDirectory(path: string, callback?: ScanProgressCallback): Promise<Song[]>
}
```

### GlobalPlayState 关键接口
```typescript
class GlobalPlayState {
  static getInstance(): GlobalPlayState
  initializeStorage(): void
  setCurrentSong(song: Song): void
  getCurrentSong(): Song | null
  setIsPlaying(playing: boolean): void
  isPlaying(): boolean
  setCurrentPosition(position: number): void
  getCurrentPosition(): number
  setPlayMode(mode: PlayMode): void
  getPlayMode(): PlayMode
}
```

### PreferencesManager 关键接口
```typescript
class PreferencesManager {
  static getInstance(): PreferencesManager
  async initialize(context: Context): Promise<boolean>
  async getPlayMode(): Promise<PlayMode>
  async setPlayMode(mode: PlayMode): Promise<void>
  async getLastSongId(): Promise<number>
  async setLastSongId(songId: number): Promise<void>
  async getLastPosition(): Promise<number>
  async setLastPosition(position: number): Promise<void>
  async getVolume(): Promise<number>
  async setVolume(volume: number): Promise<void>
}
```

---

## 枚举和常量速查

### PlayMode (播放模式)
```typescript
enum PlayMode {
  SEQUENCE = 0,   // 顺序播放
  LOOP = 1,       // 列表循环
  SINGLE = 2,     // 单曲循环
  SHUFFLE = 3     // 随机播放
}
```

### PlayerState (播放状态)
```typescript
enum PlayerState {
  IDLE = 'idle',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}
```

### 全局状态键 (PlayStateKeys)
```typescript
class PlayStateKeys {
  static readonly CURRENT_SONG: string = 'currentSong'
  static readonly IS_PLAYING: string = 'isPlaying'
  static readonly CURRENT_POSITION: string = 'currentPosition'
  static readonly PLAY_MODE: string = 'playMode'
  static readonly SONG_LIST: string = 'songList'
  static readonly CURRENT_INDEX: string = 'currentIndex'
}
```

### 支持的音频格式
```typescript
const SUPPORTED_AUDIO_EXTENSIONS: string[] = [
  '.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a'
]
```

### 权限列表
```
ohos.permission.READ_AUDIO
ohos.permission.WRITE_AUDIO
ohos.permission.READ_MEDIA
ohos.permission.MEDIA_LOCATION
ohos.permission.KEEP_BACKGROUND_RUNNING
```

---

## 初始化流程图

```
EntryAbility.onCreate()
  ↓
GlobalPlayState.initializeStorage()
  ↓
DatabaseHelper.initialize()
  ↓
PreferencesManager.initialize()
  ↓
AudioPlayerService.initialize()
  ↓
PlayController.initialize()
  ↓
EntryAbility.onWindowStageCreate()
  ↓
加载 pages/Index 页面
```

---

## 文件修改清单

需要关注的主要修改文件：

### 如果需要修改播放逻辑
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/service/AudioPlayerService.ets`

### 如果需要修改 UI
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/Index.ets`
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/PlayerPage.ets`
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/`

### 如果需要修改权限
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/module.json5`
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/PermissionManager.ets`

### 如果需要修改数据存储
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/database/DatabaseHelper.ets`
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/data/preferences/PreferencesManager.ets`

### 如果需要修改全局状态
- `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/GlobalPlayState.ets`

---

## 快速导航命令

```bash
# 查看所有源文件
find /Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets -type f -name "*.ets"

# 查看所有配置文件
find /Users/lzh/DevEcoStudioProjects/MyApplication -name "*.json5"

# 查看所有资源文件
find /Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/resources -type f

# 查看项目结构
ls -R /Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets
```

