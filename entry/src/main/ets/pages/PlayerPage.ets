import { router } from '@kit.ArkUI'
import { Song } from '../model/Song'
import { PlayMode } from '../model/PlayState'
import { TimeUtils } from '../common/utils/TimeUtils'
import { PlayStateKeys, parseSongFromJson } from '../common/GlobalPlayState'
import { PlayController } from '../common/PlayController'
import { PlayQueueService } from '../service/PlayQueueService'
import { PlayQueuePanel } from '../components/PlayQueuePanel'

/**
 * 播放器页面
 * 包含：大封面、歌曲信息、进度条、控制按钮
 * 使用 @StorageLink 与全局状态同步
 */
@Entry
@Component
struct PlayerPage {
  // 使用 @StorageLink 连接全局播放状态
  @StorageLink(PlayStateKeys.CURRENT_SONG) currentSongJson: string = ''
  @StorageLink(PlayStateKeys.IS_PLAYING) @Watch('onPlayingStateChange') isPlaying: boolean = false
  @StorageLink(PlayStateKeys.PLAY_MODE) playMode: number = PlayMode.SEQUENCE
  @StorageLink(PlayStateKeys.CURRENT_POSITION) currentPosition: number = 0
  @StorageLink(PlayStateKeys.CURRENT_DURATION) currentDuration: number = 0

  @State private isDragging: boolean = false
  @State private dragPosition: number = 0
  @State private coverRotation: number = 0  // 封面旋转角度

  // 播放控制器
  private playController: PlayController = PlayController.getInstance()
  private queueService: PlayQueueService = PlayQueueService.getInstance()
  private rotationTimer: number = -1  // 旋转动画定时器

  // 播放列表弹窗控制器
  private playQueueDialogController: CustomDialogController = new CustomDialogController({
    builder: PlayQueuePanel(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    offset: { dx: 0, dy: 0 }
  })

  aboutToAppear(): void {
    console.info('PlayerPage', 'aboutToAppear - Page loaded')
    const song = this.getCurrentSong()
    if (song) {
      console.info('PlayerPage', `Current song: ${song.title}`)
    }
    // 如果正在播放，启动旋转动画
    if (this.isPlaying) {
      this.startRotation()
    }
  }

  aboutToDisappear(): void {
    // 页面销毁时停止旋转动画
    this.stopRotation()
  }

  /**
   * 启动封面旋转动画
   */
  private startRotation(): void {
    if (this.rotationTimer !== -1) {
      return
    }
    this.rotationTimer = setInterval(() => {
      this.coverRotation = (this.coverRotation + 0.5) % 360
    }, 16) // 约60fps
  }

  /**
   * 停止封面旋转动画
   */
  private stopRotation(): void {
    if (this.rotationTimer !== -1) {
      clearInterval(this.rotationTimer)
      this.rotationTimer = -1
    }
  }

  /**
   * 获取当前歌曲对象
   */
  private getCurrentSong(): Song | null {
    return parseSongFromJson(this.currentSongJson)
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    console.info('PlayerPage', 'Go back clicked')
    try {
      router.back()
    } catch (err) {
      console.error('PlayerPage', `Go back failed: ${err}`)
    }
  }

  /**
   * 获取播放模式图标
   */
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

  /**
   * 获取播放模式名称
   */
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

  /**
   * 切换播放模式
   */
  private togglePlayMode(): void {
    this.playController.togglePlayMode()
    console.info('PlayerPage', `Play mode changed to: ${this.getModeName()}`)
  }

  /**
   * 监听播放状态变化，控制旋转动画
   */
  onPlayingStateChange(): void {
    if (this.isPlaying) {
      this.startRotation()
    } else {
      this.stopRotation()
    }
  }

  /**
   * 获取显示的播放位置
   */
  private getDisplayPosition(): number {
    return this.isDragging ? this.dragPosition : this.currentPosition
  }

  /**
   * 获取有效的时长（优先使用实时播放器时长）
   */
  private getValidDuration(): number {
    if (this.currentDuration > 0) {
      return this.currentDuration
    }
    return this.getCurrentSong()?.duration || 0
  }

  /**
   * 判断是否有有效时长
   */
  private hasValidDuration(): boolean {
    return this.getValidDuration() > 0
  }

  /**
   * 获取进度百分比
   */
  private getProgressPercent(): number {
    const duration = this.getValidDuration()
    if (duration === 0) {
      return 0
    }
    return (this.getDisplayPosition() / duration) * 100
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopBar()

      // 主内容区域
      Column() {
        // 专辑封面区域
        this.AlbumCover()

        // 歌曲信息
        this.SongInfo()

        // 进度条
        this.ProgressBar()

        // 控制按钮区
        this.ControlButtons()
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#667eea', 0.0], ['#764ba2', 0.5], ['#f093fb', 1.0]]
    })
  }

  @Builder
  TopBar() {
    Row() {
      // 返回按钮
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .fillColor('#FFFFFF')
        .onClick(() => {
          this.goBack()
        })

      // 标题区域
      Column() {
        Text(this.isPlaying ? '正在播放' : '已暂停')
          .fontSize(12)
          .fontColor('rgba(255, 255, 255, 0.7)')

        Text(this.getCurrentSong()?.album || '未知专辑')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      // 更多按钮
      Image($r('app.media.ic_more'))
        .width(24)
        .height(24)
        .fillColor('#FFFFFF')
        .onClick(() => {
          console.info('PlayerPage', 'More button clicked, navigating to settings')
          router.pushUrl({ url: 'pages/SettingsPage' })
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  AlbumCover() {
    Column() {
      // 封面容器 - 带阴影效果和旋转动画
      Stack() {
        // 封面阴影
        Column()
          .width(260)
          .height(260)
          .borderRadius(130) // 圆形封面
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .offset({ x: 0, y: 15 })
          .blur(30)

        // 唱片底盘效果
        Circle()
          .width(290)
          .height(290)
          .fill('#1a1a1a')
          .rotate({ angle: this.coverRotation })

        // 唱片纹理
        Circle()
          .width(280)
          .height(280)
          .fill('transparent')
          .stroke('#333333')
          .strokeWidth(1)
          .rotate({ angle: this.coverRotation })

        // 专辑封面（圆形）
        Image(this.getCurrentSong()?.albumArt || $r('app.media.default_album'))
          .width(180)
          .height(180)
          .borderRadius(90)
          .objectFit(ImageFit.Cover)
          .rotate({ angle: this.coverRotation })
          .shadow({
            radius: 20,
            color: 'rgba(0, 0, 0, 0.4)',
            offsetX: 0,
            offsetY: 10
          })

        // 中心圆点
        Circle()
          .width(24)
          .height(24)
          .fill('#222222')
          .rotate({ angle: this.coverRotation })

        Circle()
          .width(8)
          .height(8)
          .fill('#ffffff')
      }
    }
    .width('100%')
    .padding({ top: 30 })
    .justifyContent(FlexAlign.Center)
    .onAppear(() => {
      // 监听播放状态变化
      if (this.isPlaying) {
        this.startRotation()
      }
    })
  }

  @Builder
  SongInfo() {
    Column() {
      // 歌曲名称
      Text(this.getCurrentSong()?.title || '未知歌曲')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 歌手名称
      Text(this.getCurrentSong()?.artist || '未知艺术家')
        .fontSize(16)
        .fontColor('rgba(255, 255, 255, 0.7)')
        .margin({ top: 8 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 32, right: 32 })
    .alignItems(HorizontalAlign.Center)
  }

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
        .blockSize({ width: 16, height: 16 })
        .trackColor('rgba(255, 255, 255, 0.3)')
        .selectedColor('#FFFFFF')
        .width('100%')
        .onChange((value: number, mode: SliderChangeMode) => {
          const duration = this.getValidDuration()
          if (duration > 0) {
            const newPosition = (value / 100) * duration

            if (mode === SliderChangeMode.Begin) {
              // 开始拖动
              this.isDragging = true
              this.dragPosition = newPosition
              console.info('PlayerPage', `Slider drag begin at: ${newPosition}ms`)
            } else if (mode === SliderChangeMode.Moving) {
              // 拖动中
              this.dragPosition = newPosition
            } else if (mode === SliderChangeMode.End) {
              // 拖动结束，执行跳转
              this.isDragging = false
              this.playController.seekTo(newPosition)
              console.info('PlayerPage', `Seek to position: ${newPosition}ms`)
            } else if (mode === SliderChangeMode.Click) {
              // 点击跳转
              this.playController.seekTo(newPosition)
              console.info('PlayerPage', `Click seek to: ${newPosition}ms`)
            }
          }
        })

      // 时间显示
      Row() {
        // 当前播放时间（始终显示，即使为 0）
        Text(TimeUtils.formatDuration(this.getDisplayPosition()))
          .fontSize(12)
          .fontColor('rgba(255, 255, 255, 0.6)')

        Blank()

        // 总时长（使用实时 duration，无效时显示 --:--）
        Text(this.getValidDuration() > 0 ? TimeUtils.formatDuration(this.getValidDuration()) : '--:--')
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

  @Builder
  ControlButtons() {
    Column() {
      // 主控制按钮行
      Row() {
        // 播放模式按钮（弱化显示）
        Image(this.getModeIcon())
          .width(22)
          .height(22)
          .fillColor('rgba(255, 255, 255, 0.35)')
          .onClick(() => {
            this.togglePlayMode()
          })

        Blank()

        // 上一首（贴近播放键，对比度降低）
        Image($r('app.media.ic_previous'))
          .width(32)
          .height(32)
          .fillColor('rgba(255, 255, 255, 0.7)')
          .onClick(() => {
            console.info('PlayerPage', 'Previous button clicked')
            this.playController.playPrevious()
          })

        // 播放/暂停按钮（最大尺寸，纯白最高对比）
        Stack() {
          Circle()
            .width(72)
            .height(72)
            .fill('#FFFFFF')

          Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(32)
            .height(32)
            .fillColor('#764ba2')
        }
        .margin({ left: 20, right: 20 })
        .onClick(() => {
          console.info('PlayerPage', `Play/Pause button clicked, current state: ${this.isPlaying}`)
          this.playController.togglePlayPause()
        })

        // 下一首（贴近播放键，对比度降低）
        Image($r('app.media.ic_next'))
          .width(32)
          .height(32)
          .fillColor('rgba(255, 255, 255, 0.7)')
          .onClick(() => {
            console.info('PlayerPage', 'Next button clicked')
            this.playController.playNext()
          })

        Blank()

        // 播放列表按钮（弱化显示）
        Image($r('app.media.ic_playlist'))
          .width(22)
          .height(22)
          .fillColor('rgba(255, 255, 255, 0.35)')
          .onClick(() => {
            console.info('PlayerPage', 'Playlist button clicked')
            this.playQueueDialogController.open()
          })
      }
      .width('100%')
      .height(72)
      .padding({ left: 32, right: 32 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }
}
