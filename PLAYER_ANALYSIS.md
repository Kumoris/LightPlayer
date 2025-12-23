# HarmonyOS音乐播放器详细分析

## 1. 播放时间和进度的实现

### 1.1 时间格式化工具
**文件位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/common/utils/TimeUtils.ets`

**核心实现**:
```typescript
// 将毫秒转换为 mm:ss 格式
static formatDuration(ms: number): string {
  if (ms < 0) {
    return '0:00'
  }
  const minutes = Math.floor(ms / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

// 将毫秒转换为 hh:mm:ss 格式
static formatDurationLong(ms: number): string {
  if (ms < 0) {
    return '0:00:00'
  }
  const hours = Math.floor(ms / 3600000)
  const minutes = Math.floor((ms % 3600000) / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  
  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}
```

**特点**:
- 处理负数情况（显示 '0:00'）
- 支持两种格式: mm:ss 和 hh:mm:ss
- 自动补零处理

---

### 1.2 MiniPlayer时间显示
**文件位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/MiniPlayer.ets`

**关键代码片段 (行38-43)**:
```typescript
private formatTime(ms: number): string {
  if (ms <= 0) return '0:00'
  const totalSeconds = Math.floor(ms / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}
```

**时间显示位置 (行115-121)**:
```typescript
// 时间显示：已播放 / 总时长
if (this.duration > 0) {
  Text(`${this.formatTime(this.isDragging ? (this.dragProgress / 100 * this.duration) : this.currentPosition)} / ${this.formatTime(this.duration)}`)
    .fontSize(10)
    .fontColor('#007AFF')
    .fontWeight(FontWeight.Medium)
}
```

**特点**:
- 显示格式: `当前时间 / 总时长` (e.g., "2:15 / 4:30")
- 拖动时动态显示预期播放位置
- 字体大小: 10, 颜色: #007AFF (蓝色)

---

### 1.3 PlayerPage时间显示
**文件位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/pages/PlayerPage.ets`

**时间显示实现 (行428-438)**:
```typescript
@Builder
ProgressBar() {
  Column() {
    // 进度滑块
    Slider({
      value: this.getProgressPercent(),
      min: 0,
      max: 100,
      style: SliderStyle.OutSet
    })
      .blockColor('#FFFFFF')
      .trackColor('rgba(255, 255, 255, 0.3)')
      .selectedColor('#FFFFFF')
      .width('100%')
      .onChange((value: number, mode: SliderChangeMode) => {
        // 处理滑块变化
      })

    // 时间显示
    Row() {
      Text(TimeUtils.formatDuration(this.getDisplayPosition()))
        .fontSize(12)
        .fontColor('rgba(255, 255, 255, 0.6)')
      
      Blank()
      
      Text(TimeUtils.formatDuration(this.getCurrentSong()?.duration || 0))
        .fontSize(12)
        .fontColor('rgba(255, 255, 255, 0.6)')
    }
    .width('100%')
    .padding({ left: 4, right: 4 })
    .margin({ top: -4 })
  }
  .width('100%')
  .padding({ left: 24, right: 24 })
}
```

**特点**:
- 使用TimeUtils.formatDuration()工具方法
- 左右两侧分别显示当前时间和总时长
- 拖动时显示预期位置 `getDisplayPosition()`

---

### 1.4 PlayerDetailPanel时间显示
**文件位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/components/PlayerDetailPanel.ets`

**时间显示实现 (行440-451)**:
```typescript
@Builder
ProgressBar() {
  Column() {
    Slider({
      value: this.getProgressPercent(),
      min: 0,
      max: 100,
      style: SliderStyle.OutSet
    })
      .blockColor('#FFFFFF')
      .trackColor('rgba(255, 255, 255, 0.3)')
      .selectedColor('#FFFFFF')
      .width('100%')

    // 时间显示
    Row() {
      Text(TimeUtils.formatDuration(this.getDisplayPosition()))
        .fontSize(11)
        .fontColor('rgba(255, 255, 255, 0.6)')
      
      Blank()
      
      Text(TimeUtils.formatDuration(this.getCurrentSong()?.duration || 0))
        .fontSize(11)
        .fontColor('rgba(255, 255, 255, 0.6)')
    }
    .width('100%')
    .padding({ left: 4, right: 4 })
    .margin({ top: -4 })
  }
  .width('100%')
  .padding({ left: 20, right: 20 })
}
```

**特点**:
- 与PlayerPage相同的时间显示逻辑
- 字体略小 (11px vs 12px)
- 支持拖动时的实时预览

---

### 1.5 进度条实现分析

**进度百分比计算** (PlayerViewModel.ets 行144-149):
```typescript
getProgressPercent(): number {
  if (this.duration === 0) {
    return 0
  }
  return (this.currentPosition / this.duration) * 100
}
```

**Slider组件配置**:
- **值范围**: 0-100 (百分比)
- **step**: 0.1 (精度)
- **样式**: SliderStyle.OutSet
- **块颜色** (活跃时): #007AFF (MiniPlayer)、#FFFFFF (PlayerPage/Panel)
- **轨道颜色**: #E8E8E8 (MiniPlayer)、rgba(255, 255, 255, 0.3) (PlayerPage/Panel)

**拖动处理**:
```typescript
.onChange((value: number, mode: SliderChangeMode) => {
  if (mode === SliderChangeMode.Begin) {
    this.isDragging = true
    this.dragProgress = value
  } else if (mode === SliderChangeMode.Moving) {
    this.dragProgress = value
  } else if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
    this.isDragging = false
    const targetPosition = Math.floor((value / 100) * this.duration)
    this.onSeek?.(targetPosition)
  }
})
```

---

## 2. 播放状态反馈

### 2.1 播放状态枚举定义
**文件位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/model/PlayState.ets`

```typescript
export enum PlayerState {
  IDLE = 'idle',           // 空闲
  PREPARED = 'prepared',   // 已准备
  PLAYING = 'playing',     // 播放中
  PAUSED = 'paused',       // 已暂停
  STOPPED = 'stopped',     // 已停止
  ERROR = 'error'          // 出错
}
```

---

### 2.2 播放/暂停按钮状态
**MiniPlayer (行134-158)**:
```typescript
// 播放/暂停按钮
Stack() {
  Circle()
    .width(36)
    .height(36)
    .fill(this.isPressed ? '#F0F0F0' : '#FFFFFF')
    .stroke('#E8E8E8')
    .strokeWidth(1)

  Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
    .width(18)
    .height(18)
    .fillColor('#333333')
}
.onTouch((event) => {
  if (event.type === TouchType.Down) {
    this.isPressed = true
  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
    this.isPressed = false
  }
})
.onClick(() => {
  this.onPlayPauseClick?.()
})
```

**状态反馈方式**:
- **图标切换**: isPlaying ? ic_pause : ic_play
- **按压反馈**: 按下时背景变为 #F0F0F0
- **尺寸**: 36x36 (MiniPlayer)、64x64 (PlayerPage)、64x64 (PlayerDetailPanel)

---

### 2.3 播放中指示器
**MiniPlayer (行93-106)** - 动画波形指示：
```typescript
if (this.isPlaying) {
  // 播放中指示器
  Row() {
    ForEach([1, 2, 3], (item: number) => {
      Column()
        .width(2.5)
        .height(item === 2 ? 9 : 5)  // 中间高，两边矮
        .backgroundColor('#007AFF')
        .borderRadius(1)
        .margin({ right: 1.5 })
    })
  }
  .margin({ right: 5 })
}
```

**特点**:
- 三根竖条组成的波形
- 中间条高度: 9, 两边条高度: 5
- 颜色: #007AFF (蓝色)
- 宽度: 2.5, 有圆角(1)

---

### 2.4 封面旋转动画反馈
**PlayerPage (行62-79)**:
```typescript
private startRotation(): void {
  if (this.rotationTimer !== -1) {
    return
  }
  this.rotationTimer = setInterval(() => {
    this.coverRotation = (this.coverRotation + 0.5) % 360
  }, 16)  // 约60fps
}

private stopRotation(): void {
  if (this.rotationTimer !== -1) {
    clearInterval(this.rotationTimer)
    this.rotationTimer = -1
  }
}

// 监听播放状态变化
onPlayingStateChange(): void {
  if (this.isPlaying) {
    this.startRotation()
  } else {
    this.stopRotation()
  }
}
```

**特点**:
- 播放时连续旋转，每帧增加 0.5 度
- 暂停时停止旋转
- 帧率约 60fps (setInterval 16ms)

---

### 2.5 加载状态反馈
**PlayerViewModel (行40-44)**:
```typescript
onStateChanged: (state: PlayerState) => {
  this.isPlaying = state === PlayerState.PLAYING
  this.isLoading = state === PlayerState.IDLE
}
```

---

## 3. 功能图标分析

### 3.1 图标资源目录
**位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/resources/base/media/`

### 3.2 图标清单

| 图标名称 | 文件名 | 用途 | 尺寸(像素) |
|---------|-------|------|-----------|
| 播放 | ic_play.svg | 播放按钮 | 116 |
| 暂停 | ic_pause.svg | 暂停按钮 | 134 |
| 下一首 | ic_next.svg | 下一首按钮 | 138 |
| 上一首 | ic_previous.svg | 上一首按钮 | 130 |
| 播放列表 | ic_playlist.svg | 播放列表按钮 | 189 |
| 返回 | ic_back.svg | 返回按钮/下拉 | 148 |
| 更多 | ic_more.svg | 更多菜单 | 204 |
| 搜索 | ic_search.svg | 搜索/分享 | 337 |
| 扫描 | ic_scan.svg | 收藏/下载 | 326 |
| 播放状态 | ic_playing.svg | 播放指示 | 189 |
| 顺序播放 | ic_mode_sequence.svg | 播放模式 | 231 |
| 列表循环 | ic_mode_loop.svg | 播放模式 | 204 |
| 单曲循环 | ic_mode_single.svg | 播放模式 | 220 |
| 随机播放 | ic_mode_shuffle.svg | 播放模式 | 276 |
| 空状态 | ic_empty.svg | 列表为空 | 220 |
| 删除 | ic_delete.svg | 删除项目 | 180 |
| 关闭 | ic_close.svg | 关闭对话框 | 204 |
| 默认专辑 | default_album.svg | 占位符 | 213 |

### 3.3 图标复用情况

**存在的问题**:
1. **语义重复**: 
   - `ic_scan.svg` 同时用于收藏和下载
   - `ic_more.svg` 用于菜单、评论、关闭
   - `ic_search.svg` 用于搜索和分享

2. **使用位置**:

```typescript
// PlayerDetailPanel SongInfo (行362-399)
// 收藏按钮
Image($r('app.media.ic_scan'))  // ic_scan

// 下载按钮
Image($r('app.media.ic_scan'))  // 同一图标！

// 评论按钮
Image($r('app.media.ic_more'))  // ic_more

// 分享按钮
Image($r('app.media.ic_search'))  // ic_search
```

```typescript
// PlayerPage SongInfo (行334-378)
// 收藏按钮 - 支持选中状态
Image($r('app.media.ic_scan'))
  .fillColor(this.isFavorite ? '#FF6B6B' : 'rgba(255, 255, 255, 0.6)')

// 其他按钮同样复用
```

---

## 4. 异常数据处理

### 4.1 空数据显示策略

**歌曲标题** - MiniPlayer (行83):
```typescript
Text(this.getCurrentSong()?.title || '未在播放')
```

**歌手名称** - MiniPlayer (行108):
```typescript
Text(this.getCurrentSong()?.artist || '点击选择歌曲')
```

**专辑名称** - PlayerPage (行218):
```typescript
Text(this.getCurrentSong()?.album || '未知专辑')
```

**PlayerDetailPanel (行222)**:
```typescript
Text(this.getCurrentSong()?.album || '未知专辑')
```

### 4.2 时长异常处理

**时长为0或负数** - TimeUtils.formatDuration():
```typescript
static formatDuration(ms: number): string {
  if (ms < 0) {
    return '0:00'
  }
  // ... 处理正常情况
}
```

**进度条处理** - getProgressPercent():
```typescript
getProgressPercent(): number {
  const song = this.getCurrentSong()
  if (!song || song.duration === 0) {
    return 0
  }
  return (this.getDisplayPosition() / song.duration) * 100
}
```

**时间显示** - PlayerPage (行402-424):
```typescript
.onChange((value: number, mode: SliderChangeMode) => {
  const song = this.getCurrentSong()
  if (song && song.duration > 0) {
    const newPosition = (value / 100) * song.duration
    // ... 处理seek
  }
})
```

### 4.3 专辑封面处理

**默认占位符** - MiniPlayer (行59):
```typescript
Image(this.getCurrentSong()?.albumArt || $r('app.media.default_album'))
  .width(44)
  .height(44)
  .borderRadius(6)
  .objectFit(ImageFit.Cover)
```

**PlayerPage (行274)**:
```typescript
Image(this.getCurrentSong()?.albumArt || $r('app.media.default_album'))
  .width(180)
  .height(180)
  .borderRadius(90)
  .objectFit(ImageFit.Cover)
```

### 4.4 缺失数据处理总结

| 字段 | 空值显示 | 处理位置 |
|------|---------|---------|
| title | '未在播放' | MiniPlayer |
| artist | '点击选择歌曲' | MiniPlayer |
| album | '未知专辑' | PlayerPage/Panel |
| duration | 0 | Song.duration默认值 |
| albumArt | default_album.svg | 所有image组件 |
| position | 0 | 初始化时设置 |

---

## 5. 播放模式

### 5.1 播放模式定义
**文件位置**: `/Users/lzh/DevEcoStudioProjects/MyApplication/entry/src/main/ets/model/PlayState.ets`

```typescript
export enum PlayMode {
  SEQUENCE = 0,    // 顺序播放
  LOOP = 1,        // 列表循环
  SINGLE = 2,      // 单曲循环
  SHUFFLE = 3      // 随机播放
}
```

### 5.2 播放模式切换流程

**PlayQueueService (行431-437)**:
```typescript
async togglePlayMode(): Promise<PlayMode> {
  const modes: PlayMode[] = [
    PlayMode.SEQUENCE,
    PlayMode.LOOP,
    PlayMode.SINGLE,
    PlayMode.SHUFFLE
  ]
  const currentModeIndex = modes.indexOf(this.playMode)
  const nextMode = modes[(currentModeIndex + 1) % modes.length]
  await this.setPlayMode(nextMode)
  return nextMode
}
```

**切换顺序**: SEQUENCE → LOOP → SINGLE → SHUFFLE → SEQUENCE (循环)

### 5.3 播放模式图标映射

**PlayerPage.getModeIcon() (行99-112)**:
```typescript
private getModeIcon(): Resource {
  switch (this.playMode) {
    case PlayMode.SEQUENCE:
      return $r('app.media.ic_mode_sequence')
    case PlayMode.LOOP:
      return $r('app.media.ic_mode_loop')
    case PlayMode.SINGLE:
      return $r('app.media.ic_mode_single')
    case PlayMode.SHUFFLE:
      return $r('app.media.ic_mode_shuffle')
    default:
      return $r('app.media.ic_mode_sequence')
  }
}
```

### 5.4 播放模式名称

**PlayerPage.getModeName() (行117-130)**:
```typescript
private getModeName(): string {
  switch (this.playMode) {
    case PlayMode.SEQUENCE:
      return '顺序播放'
    case PlayMode.LOOP:
      return '列表循环'
    case PlayMode.SINGLE:
      return '单曲循环'
    case PlayMode.SHUFFLE:
      return '随机播放'
    default:
      return '顺序播放'
  }
}
```

### 5.5 播放模式切换入口

**1. PlayerPage 播放模式按钮** (行451-461):
```typescript
@Builder
ControlButtons() {
  Row() {
    // 播放模式按钮
    Column() {
      Image(this.getModeIcon())
        .width(26)
        .height(26)
        .fillColor('rgba(255, 255, 255, 0.8)')
    }
    .onClick(() => {
      this.togglePlayMode()
    })
```

**2. PlayerDetailPanel 播放模式按钮** (行465-474):
```typescript
// 播放模式按钮
Column() {
  Image(this.getModeIcon())
    .width(24)
    .height(24)
    .fillColor('rgba(255, 255, 255, 0.8)')
}
.onClick(() => {
  this.togglePlayMode()
})
```

**3. PlayerControls 播放模式按钮** (行60-66):
```typescript
// 播放模式
Image(this.getModeIcon())
  .width(28)
  .height(28)
  .fillColor('#666666')
  .onClick(() => {
    this.onModeClick?.()
  })
```

### 5.6 播放模式提示显示

**PlayerPage (行521-525)**:
```typescript
// 播放模式提示
Text(this.getModeName())
  .fontSize(11)
  .fontColor('rgba(255, 255, 255, 0.5)')
  .margin({ top: 16 })
```

**PlayerDetailPanel (行530-534)**:
```typescript
// 播放模式提示
Text(this.getModeName())
  .fontSize(10)
  .fontColor('rgba(255, 255, 255, 0.5)')
  .margin({ top: 12 })
```

### 5.7 播放模式工作机制

**顺序播放** (SEQUENCE):
- 从列表开始，逐首播放，到末尾时停止或循环

**列表循环** (LOOP):
- 播放到列表末尾时自动回到列表首部继续播放

**单曲循环** (SINGLE):
- 同一首歌曲无限循环播放

**随机播放** (SHUFFLE):
- 按随机顺序播放列表中的歌曲

**实现位置** - GlobalPlayState.playNext() (行250-275):
```typescript
playNext(): void {
  const songList = this.getSongList()
  if (songList.length === 0) {
    return
  }

  const currentIndex = AppStorage.get<number>(PlayStateKeys.CURRENT_INDEX) ?? -1
  const playMode = AppStorage.get<number>(PlayStateKeys.PLAY_MODE) ?? PlayMode.SEQUENCE
  let nextIndex: number

  switch (playMode) {
    case PlayMode.SHUFFLE:
      nextIndex = Math.floor(Math.random() * songList.length)
      break
    case PlayMode.SINGLE:
      nextIndex = currentIndex
      break
    default:
      nextIndex = (currentIndex + 1) % songList.length
  }

  const nextSong = songList[nextIndex]
  if (nextSong) {
    this.playSong(nextSong, nextIndex)
  }
}
```

---

## 总结

| 方面 | 关键文件 | 核心特性 |
|------|---------|---------|
| **时间显示** | TimeUtils.ets | 支持mm:ss和hh:mm:ss格式，负数处理 |
| **进度条** | MiniPlayer/PlayerPage | Slider 0-100%，支持拖动和点击 |
| **播放状态** | PlayState.ets | 6种状态，图标和动画反馈 |
| **封面旋转** | PlayerPage | 60fps连续旋转，播放/暂停同步 |
| **图标管理** | 资源目录 | 18个图标，部分复用 |
| **异常处理** | 各组件 | 空值显示预设文本或占位符 |
| **播放模式** | PlayQueueService | 4种模式，循环切换入口多处 |

