# HarmonyOS音乐播放器 - 关键代码片段速查

## 1. 时间处理

### 1.1 时间格式化 (TimeUtils.ets)
```typescript
// 毫秒转 mm:ss (如: "2:15")
static formatDuration(ms: number): string {
  if (ms < 0) return '0:00'
  const minutes = Math.floor(ms / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}

// 毫秒转 hh:mm:ss (自适应)
static formatDurationLong(ms: number): string {
  if (ms < 0) return '0:00:00'
  const hours = Math.floor(ms / 3600000)
  const minutes = Math.floor((ms % 3600000) / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  
  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}
```

### 1.2 MiniPlayer时间显示 (MiniPlayer.ets, 行115-121)
```typescript
// 时间显示：已播放 / 总时长，拖动时显示预期位置
if (this.duration > 0) {
  Text(`${this.formatTime(this.isDragging ? (this.dragProgress / 100 * this.duration) : this.currentPosition)} / ${this.formatTime(this.duration)}`)
    .fontSize(10)
    .fontColor('#007AFF')
    .fontWeight(FontWeight.Medium)
}
```

### 1.3 PlayerPage时间显示 (PlayerPage.ets, 行427-441)
```typescript
Row() {
  Text(TimeUtils.formatDuration(this.getDisplayPosition()))
    .fontSize(12)
    .fontColor('rgba(255, 255, 255, 0.6)')
  
  Blank()  // 填充空间
  
  Text(TimeUtils.formatDuration(this.getCurrentSong()?.duration || 0))
    .fontSize(12)
    .fontColor('rgba(255, 255, 255, 0.6)')
}
.width('100%')
.padding({ left: 4, right: 4 })
.margin({ top: -4 })
```

---

## 2. 进度条处理

### 2.1 进度百分比计算 (PlayerViewModel.ets, 行144-149)
```typescript
getProgressPercent(): number {
  if (this.duration === 0) {
    return 0
  }
  return (this.currentPosition / this.duration) * 100
}

// 获取显示进度（拖动时用拖动值）
private getDisplayProgress(): number {
  return this.isDragging ? this.dragProgress : this.progress
}
```

### 2.2 Slider拖动处理 (MiniPlayer.ets, 行201-227)
```typescript
Row() {
  Slider({
    value: this.getDisplayProgress(),
    min: 0,
    max: 100,
    step: 0.1,
    style: SliderStyle.OutSet
  })
    .blockColor('#007AFF')
    .trackColor('#E8E8E8')
    .selectedColor('#007AFF')
    .blockSize({ width: this.isDragging ? 14 : 10, height: this.isDragging ? 14 : 10 })
    .trackThickness(this.isDragging ? 4 : 3)
    .onChange((value: number, mode: SliderChangeMode) => {
      if (mode === SliderChangeMode.Begin) {
        this.isDragging = true
        this.dragProgress = value
      } else if (mode === SliderChangeMode.Moving) {
        this.dragProgress = value
      } else if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
        this.isDragging = false
        // 计算目标位置（毫秒）
        const targetPosition = Math.floor((value / 100) * this.duration)
        this.onSeek?.(targetPosition)
      }
    })
    .width('100%')
}
.width('100%')
.padding({ left: 12, right: 12 })
.height(20)
```

### 2.3 PlayerPage Slider配置 (PlayerPage.ets, 行390-425)
```typescript
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
    const song = this.getCurrentSong()
    if (song && song.duration > 0) {
      const newPosition = (value / 100) * song.duration

      if (mode === SliderChangeMode.Begin) {
        this.isDragging = true
        this.dragPosition = newPosition
        console.info('PlayerPage', `Slider drag begin at: ${newPosition}ms`)
      } else if (mode === SliderChangeMode.Moving) {
        this.dragPosition = newPosition
      } else if (mode === SliderChangeMode.End) {
        this.isDragging = false
        this.playController.seekTo(newPosition)
        console.info('PlayerPage', `Seek to position: ${newPosition}ms`)
      } else if (mode === SliderChangeMode.Click) {
        this.playController.seekTo(newPosition)
        console.info('PlayerPage', `Click seek to: ${newPosition}ms`)
      }
    }
  })
```

---

## 3. 播放状态反馈

### 3.1 播放/暂停图标切换 (PlayerPage.ets, 行475-491)
```typescript
Stack() {
  Circle()
    .width(72)
    .height(72)
    .fill('#FFFFFF')

  // 根据 isPlaying 状态切换图标
  Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
    .width(32)
    .height(32)
    .fillColor('#764ba2')
}
.margin({ left: 28, right: 28 })
.onClick(() => {
  console.info('PlayerPage', `Play/Pause button clicked, current state: ${this.isPlaying}`)
  this.playController.togglePlayPause()
})
```

### 3.2 封面旋转动画 (PlayerPage.ets, 行62-79)
```typescript
private startRotation(): void {
  if (this.rotationTimer !== -1) {
    return
  }
  // 每16ms增加0.5度 = 60fps旋转
  this.rotationTimer = setInterval(() => {
    this.coverRotation = (this.coverRotation + 0.5) % 360
  }, 16)
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

### 3.3 播放中指示器 (MiniPlayer.ets, 行93-106)
```typescript
if (this.isPlaying) {
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

### 3.4 按压反馈 (MiniPlayer.ets, 行148-154)
```typescript
.onTouch((event) => {
  if (event.type === TouchType.Down) {
    this.isPressed = true
  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
    this.isPressed = false
  }
})
```

---

## 4. 图标使用

### 4.1 图标引用语法
```typescript
// 基本用法
Image($r('app.media.ic_play'))
  .width(32)
  .height(32)
  .fillColor('#FFFFFF')

// 动态颜色
Image($r('app.media.ic_play'))
  .fillColor(this.isFavorite ? '#FF6B6B' : 'rgba(255, 255, 255, 0.6)')

// 旋转
Image($r('app.media.ic_back'))
  .rotate({ angle: -90 })  // 向下箭头
```

### 4.2 播放模式图标映射 (PlayerPage.ets, 行99-112)
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

---

## 5. 异常数据处理

### 5.1 空值处理与默认显示
```typescript
// 歌曲标题（MiniPlayer）
Text(this.getCurrentSong()?.title || '未在播放')

// 歌手名称（MiniPlayer）
Text(this.getCurrentSong()?.artist || '点击选择歌曲')

// 专辑名称（PlayerPage/Panel）
Text(this.getCurrentSong()?.album || '未知专辑')

// 专辑封面
Image(this.getCurrentSong()?.albumArt || $r('app.media.default_album'))
  .width(180)
  .height(180)
  .borderRadius(90)
  .objectFit(ImageFit.Cover)
```

### 5.2 时长异常处理
```typescript
// 负数或0时长处理
static formatDuration(ms: number): string {
  if (ms < 0) {
    return '0:00'
  }
  // ... 正常处理
}

// 进度计算时的安全检查
private getProgressPercent(): number {
  const song = this.getCurrentSong()
  if (!song || song.duration === 0) {
    return 0
  }
  return (this.getDisplayPosition() / song.duration) * 100
}

// Slider变化时的验证
.onChange((value: number, mode: SliderChangeMode) => {
  const song = this.getCurrentSong()
  if (song && song.duration > 0) {
    const newPosition = (value / 100) * song.duration
    // ... 处理跳转
  }
})
```

---

## 6. 播放模式切换

### 6.1 模式定义 (PlayState.ets)
```typescript
export enum PlayMode {
  SEQUENCE = 0,    // 顺序播放
  LOOP = 1,        // 列表循环
  SINGLE = 2,      // 单曲循环
  SHUFFLE = 3      // 随机播放
}
```

### 6.2 模式切换实现 (PlayQueueService.ets, 行431-437)
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

### 6.3 播放模式按钮 (PlayerPage.ets, 行451-461)
```typescript
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

### 6.4 模式名称显示 (PlayerPage.ets, 行117-130)
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

### 6.5 模式提示显示 (PlayerPage.ets, 行521-525)
```typescript
Text(this.getModeName())
  .fontSize(11)
  .fontColor('rgba(255, 255, 255, 0.5)')
  .margin({ top: 16 })
```

### 6.6 模式工作机制 (GlobalPlayState.ets, 行250-275)
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
      // 顺序和循环都使用相同逻辑，区别在末尾处理
      nextIndex = (currentIndex + 1) % songList.length
  }

  const nextSong = songList[nextIndex]
  if (nextSong) {
    this.playSong(nextSong, nextIndex)
  }
}
```

---

## 7. 全局状态管理

### 7.1 AppStorage初始化 (GlobalPlayState.ets, 行100-132)
```typescript
initializeStorage(): void {
  // 当前歌曲（JSON字符串）
  if (!AppStorage.has(PlayStateKeys.CURRENT_SONG)) {
    AppStorage.setOrCreate<string>(PlayStateKeys.CURRENT_SONG, '')
  }

  // 播放状态
  if (!AppStorage.has(PlayStateKeys.IS_PLAYING)) {
    AppStorage.setOrCreate<boolean>(PlayStateKeys.IS_PLAYING, false)
  }

  // 当前播放位置（毫秒）
  if (!AppStorage.has(PlayStateKeys.CURRENT_POSITION)) {
    AppStorage.setOrCreate<number>(PlayStateKeys.CURRENT_POSITION, 0)
  }

  // 播放模式
  if (!AppStorage.has(PlayStateKeys.PLAY_MODE)) {
    AppStorage.setOrCreate<number>(PlayStateKeys.PLAY_MODE, PlayMode.SEQUENCE)
  }

  // 歌曲列表（JSON字符串）
  if (!AppStorage.has(PlayStateKeys.SONG_LIST)) {
    AppStorage.setOrCreate<string>(PlayStateKeys.SONG_LIST, '[]')
  }

  // 当前播放索引
  if (!AppStorage.has(PlayStateKeys.CURRENT_INDEX)) {
    AppStorage.setOrCreate<number>(PlayStateKeys.CURRENT_INDEX, -1)
  }

  console.info('GlobalPlayState', 'Storage initialized successfully')
}
```

### 7.2 在组件中使用 @StorageLink (PlayerPage.ets, 行18-22)
```typescript
@StorageLink(PlayStateKeys.CURRENT_SONG) currentSongJson: string = ''
@StorageLink(PlayStateKeys.IS_PLAYING) @Watch('onPlayingStateChange') isPlaying: boolean = false
@StorageLink(PlayStateKeys.PLAY_MODE) playMode: number = PlayMode.SEQUENCE
@StorageLink(PlayStateKeys.CURRENT_POSITION) currentPosition: number = 0
```

### 7.3 解析JSON歌曲数据 (GlobalPlayState.ets, 行323-334)
```typescript
export function parseSongFromJson(songJson: string): Song | null {
  if (!songJson || songJson.length === 0) {
    return null
  }
  try {
    const data: SongData = JSON.parse(songJson) as SongData
    return dataToSong(data)
  } catch (e) {
    console.error('parseSongFromJson', `Parse failed: ${e}`)
    return null
  }
}
```

---

## 8. 常用工作流程

### 8.1 获取当前歌曲对象
```typescript
private getCurrentSong(): Song | null {
  return parseSongFromJson(this.currentSongJson)
}
```

### 8.2 播放/暂停切换
```typescript
async togglePlayPause(): Promise<void> {
  const isPlaying = AppStorage.get<boolean>(PlayStateKeys.IS_PLAYING) ?? false
  if (isPlaying) {
    await this.pause()
  } else {
    await this.resume()
  }
}
```

### 8.3 跳转到指定时间
```typescript
async seekTo(positionMs: number): Promise<void> {
  await this.audioService.seekTo(positionMs)
  this.globalState.setCurrentPosition(positionMs)
}
```

---

## 参考：项目Key定义
```typescript
class PlayStateKeys {
  static readonly CURRENT_SONG = 'currentSong'      // Song (JSON)
  static readonly IS_PLAYING = 'isPlaying'          // boolean
  static readonly CURRENT_POSITION = 'currentPosition'  // number (ms)
  static readonly PLAY_MODE = 'playMode'            // PlayMode (enum)
  static readonly SONG_LIST = 'songList'            // Song[] (JSON)
  static readonly CURRENT_INDEX = 'currentIndex'    // number
}
```

