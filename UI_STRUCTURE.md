# 鸿蒙音乐播放器 - UI结构完整指南

## 快速导航

### 页面文件（4个主要页面）
- `/entry/src/main/ets/pages/Index.ets` - 主页（歌曲列表、播放列表、设置）
- `/entry/src/main/ets/pages/PlayerPage.ets` - 全屏播放器
- `/entry/src/main/ets/pages/SearchPage.ets` - 搜索功能
- `/entry/src/main/ets/pages/SettingsPage.ets` - 设置选项

### 核心组件（5个关键组件）
- `/entry/src/main/ets/components/MiniPlayer.ets` - **核心播放控制栏**（底部64px）
- `/entry/src/main/ets/components/PlayerControls.ets` - 播放器页面控制按钮
- `/entry/src/main/ets/components/MusicItem.ets` - 歌曲列表项（72px）
- `/entry/src/main/ets/components/SongItem.ets` - 备用歌曲列表项（64px）
- `/entry/src/main/ets/components/PlayQueuePanel.ets` - 播放队列弹窗

### 应用入口
- `/entry/src/main/ets/entryability/EntryAbility.ets` - UIAbility应用入口

### 全局状态管理
- `/entry/src/main/ets/common/GlobalPlayState.ets` - AppStorage全局播放状态

---

## MiniPlayer 迷你播放器详解

### 位置和尺寸
- 固定在主页面（Index.ets）底部
- 高度：64px（包含2px进度条 + 62px主体）
- 宽度：100%屏幕宽度
- Z轴：显示在所有内容上方

### 布局结构
```
┌─────────────────────────────────────────────────────────┐
│ ═════════════════════════════════════════════════════════ │ 2px进度条
├─────────────────────────────────────────────────────────┤
│ [48×48]  标题文本  ▮▮ [40×40] [24×24] [22×22]           │ 62px
│  封面     歌手名    播放 播放/暂停 下一首 列表            │
└─────────────────────────────────────────────────────────┘
```

### 组件接收参数（@Prop）
```typescript
@Prop currentSongJson: string = ''           // 当前歌曲JSON字符串
@Prop isPlaying: boolean = false             // 播放状态
@Prop progress: number = 0                   // 进度百分比（0-100）
```

### 事件回调
```typescript
onPlayPauseClick?: () => void                // 点击播放/暂停按钮
onNextClick?: () => void                     // 点击下一首按钮
onPlayerClick?: () => void                   // 点击歌曲信息区域
onPlaylistClick?: () => void                 // 点击播放列表按钮
```

### 使用示例（在Index.ets中）
```typescript
if (this.currentSongJson && !this.isLoading) {
  MiniPlayer({
    currentSongJson: this.currentSongJson,
    isPlaying: this.isPlaying,
    progress: this.getProgressPercent(),
    onPlayPauseClick: () => {
      this.playController.togglePlayPause()
    },
    onNextClick: () => {
      this.playController.playNext()
    },
    onPlayerClick: () => {
      router.pushUrl({ url: 'pages/PlayerPage' })
    },
    onPlaylistClick: () => {
      this.playQueueDialogController.open()
    }
  })
}
```

---

## 路由配置

### 所有路由（基于字符串）
```
Index (主入口)
  ↓ router.pushUrl({ url: 'pages/PlayerPage' })
  └─ PlayerPage (全屏播放)
      ↓ router.back()
      └─ Index

Index
  ↓ router.pushUrl({ url: 'pages/SearchPage' })
  └─ SearchPage (搜索)
      ↓ router.back()
      └─ Index

Index (Tab切换)
  └─ SettingsPage (设置) [内部Tab，无导航]
```

### 路由模式
- **RouterMode.Single**: 防止重复打开相同页面
- **无参数传递**: 所有状态通过AppStorage全局同步

---

## 全局状态字段

位置：`GlobalPlayState.ets` 中的 AppStorage

| 字段 | 类型 | 说明 |
|------|------|------|
| `CURRENT_SONG` | string(JSON) | 当前播放歌曲序列化数据 |
| `IS_PLAYING` | boolean | 播放状态 |
| `PLAY_MODE` | number | 播放模式(0-3) |
| `CURRENT_POSITION` | number | 播放位置(毫秒) |
| `CURRENT_INDEX` | number | 当前歌曲在列表中的索引 |

### 状态同步机制
```typescript
// 在任何页面/组件中使用 @StorageLink 连接全局状态
@StorageLink(PlayStateKeys.CURRENT_SONG) currentSongJson: string = ''
@StorageLink(PlayStateKeys.IS_PLAYING) isPlaying: boolean = false
// 修改这些变量会自动同步到所有其他使用该字段的组件
```

---

## 页面结构总览

### Index.ets - 主页面
```
Stack (对齐底部)
├─ Column (主内容)
│  ├─ TitleBar (顶部标题栏 - 56px)
│  │   ├─ 标题文本
│  │   ├─ 搜索按钮 → SearchPage
│  │   ├─ 扫描按钮 → 刷新扫描
│  │   └─ 设置按钮 → SettingsPage
│  │
│  ├─ TabBar (标签栏 - 44px)
│  │   ├─ Tab0: 歌曲
│  │   ├─ Tab1: 播放列表
│  │   └─ Tab2: 设置
│  │
│  └─ Content (内容区域 - 自适应)
│     ├─ SongListContent (歌曲列表)
│     │  └─ LazyForEach
│     │     └─ MusicItem (72px高)
│     ├─ PlaylistContent (播放列表)
│     │  └─ List
│     │     └─ Playlist项 (72px高)
│     └─ SettingsContent (设置)
│        └─ List
│           └─ Setting项 (56px高)
│
└─ MiniPlayer (底部固定 - 64px高)
   ├─ 进度条
   ├─ 封面
   ├─ 歌曲信息
   ├─ 控制按钮
   └─ 播放列表按钮
   
自定义对话框:
└─ PlayQueuePanel (底部弹窗 - 60%高)
```

### PlayerPage.ets - 播放详情页
```
Column
├─ TopBar (56px)
│  ├─ 返回按钮
│  ├─ 标题
│  └─ 更多按钮
│
├─ AlbumCover (主内容自适应)
│  └─ 旋转唱片封面（180x180）
│     ├─ 唱片背板
│     ├─ 唱片纹理环
│     ├─ 专辑封面（旋转）
│     └─ 中心圆点
│
├─ SongInfo (动态)
│  ├─ 歌曲名
│  ├─ 歌手名
│  └─ 功能按钮行（收藏、下载、评论、分享）
│
├─ ProgressBar (动态)
│  ├─ 进度滑块（可拖动）
│  ├─ 时间显示（当前/总计）
│
└─ ControlButtons (动态)
   ├─ 播放模式按钮
   ├─ 上一首
   ├─ 播放/暂停（64x64圆形）
   ├─ 下一首
   ├─ 播放列表按钮
   └─ 模式提示文字
```

### SearchPage.ets - 搜索页
```
Column
├─ TopBar (搜索框输入行)
│  ├─ 返回按钮
│  └─ 搜索输入框
│
└─ Content
   ├─ 搜索历史（当showHistory=true）
   │  └─ List
   │     └─ 历史关键词项
   │
   └─ 搜索结果（当showHistory=false）
      └─ List
         └─ 结果歌曲项
```

### SettingsPage.ets - 设置页
```
Column
├─ TopBar
│  └─ 返回按钮 + 标题
│
└─ SettingsList
   ├─ 扫描音乐
   ├─ 选择文件
   ├─ 定时关闭
   ├─ 更多设置
   └─ 关于
```

---

## 数据流向

### 播放流程
```
MusicItem 点击
  ↓
Index.playSong(song, index)
  ↓
PlayController.playSong(song, index, songList)
  ↓
AudioPlayerService.play(song)
  ↓
GlobalPlayState.setCurrentSong(song)   // 更新全局状态
GlobalPlayState.setIsPlaying(true)
  ↓
@StorageLink 自动更新
  ↓
MiniPlayer 和 PlayerPage 自动刷新显示
```

### 状态同步流程
```
任何服务修改播放状态
  ↓
GlobalPlayState 更新 AppStorage
  ↓
所有 @StorageLink 连接的组件自动响应
  ↓
UI 重新渲染
```

---

## 颜色系统

| 用途 | 颜色 | 说明 |
|------|------|------|
| 主色 | #007AFF | iOS蓝，用于活跃元素 |
| 背景 | #FFFFFF | 白色背景 |
| 浅灰 | #F5F5F5 | 容器背景 |
| 文字主 | #333333 | 标题和重要文字 |
| 文字次 | #666666 | 副文字 |
| 文字弱 | #999999 | 提示和禁用文字 |
| 分隔线 | #E0E0E0/#F0F0F0 | Divider颜色 |
| 播放器BG | 渐变紫 | PlayerPage背景渐变 |

---

## 尺寸规范

| 元素 | 高度 | 说明 |
|------|------|------|
| TopBar | 56px | 所有页面标准顶栏 |
| TabBar | 44px | Index标签栏 |
| MiniPlayer | 64px | 底部播放栏 |
| MusicItem | 72px | 歌曲列表项 |
| SongItem | 64px | 备用列表项 |
| ListItem | 56px | 通用列表项 |
| 进度条 | 2px | 细线进度 |
| 唱片 | 180px直径 | PlayerPage的封面 |

---

## 关键代码片段

### 在Index中使用MiniPlayer
```typescript
if (this.currentSongJson && !this.isLoading) {
  MiniPlayer({
    currentSongJson: this.currentSongJson,
    isPlaying: this.isPlaying,
    progress: this.getProgressPercent(),
    onPlayPauseClick: () => {
      this.playController.togglePlayPause()
    },
    onNextClick: () => {
      this.playController.playNext()
    },
    onPlayerClick: () => {
      router.pushUrl({ url: 'pages/PlayerPage' }, 
                      router.RouterMode.Single, 
                      (err) => {
        if (err) console.error('Navigation failed')
      })
    },
    onPlaylistClick: () => {
      this.playQueueDialogController.open()
    }
  })
}
```

### 状态监听示例
```typescript
@StorageLink(PlayStateKeys.CURRENT_SONG) currentSongJson: string = ''
@StorageLink(PlayStateKeys.IS_PLAYING) @Watch('onPlayingStateChange') isPlaying: boolean = false

onPlayingStateChange(): void {
  if (this.isPlaying) {
    // 开始播放 - 启动旋转动画
    this.startRotation()
  } else {
    // 暂停播放 - 停止旋转动画
    this.stopRotation()
  }
}
```

### 导航示例
```typescript
// 前进导航
router.pushUrl({ 
  url: 'pages/PlayerPage' 
}, router.RouterMode.Single, (err) => {
  if (err) console.error(JSON.stringify(err))
})

// 后退导航
router.back()
```

---

## 文件清单

### Pages (4个)
- `/entry/src/main/ets/pages/Index.ets`
- `/entry/src/main/ets/pages/PlayerPage.ets`
- `/entry/src/main/ets/pages/SearchPage.ets`
- `/entry/src/main/ets/pages/SettingsPage.ets`

### Components (6个)
- `/entry/src/main/ets/components/MiniPlayer.ets`
- `/entry/src/main/ets/components/PlayerControls.ets`
- `/entry/src/main/ets/components/MusicItem.ets`
- `/entry/src/main/ets/components/SongItem.ets`
- `/entry/src/main/ets/components/PlayQueuePanel.ets`
- `/entry/src/main/ets/components/Index.ets` (导出)

### Core Support
- `/entry/src/main/ets/entryability/EntryAbility.ets`
- `/entry/src/main/ets/common/GlobalPlayState.ets`
- `/entry/src/main/ets/common/PlayController.ets`
- `/entry/src/main/ets/service/AudioPlayerService.ets`
- `/entry/src/main/ets/service/PlayQueueService.ets`

---

## 开发速查

### 添加新UI元素到MiniPlayer
1. 修改 `MiniPlayer.ets` 中的 build() 方法
2. 添加对应的 @Prop 和回调
3. 在 `Index.ets` 中更新 MiniPlayer() 调用
4. 在 PlayController 中添加业务逻辑

### 添加新页面
1. 创建 `/pages/NewPage.ets`
2. 使用 `@Entry @Component struct NewPage`
3. 在导航源页面添加 `router.pushUrl({ url: 'pages/NewPage' })`
4. 在新页面添加 `router.back()` 返回

### 修改路由
- 所有路由都在各页面中使用 router API
- 无需修改配置文件，字符串即为路由标识
- 状态通过 AppStorage 全局同步

---

最后更新：2025-12-22
