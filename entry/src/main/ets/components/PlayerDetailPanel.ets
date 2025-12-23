import { Song } from '../model/Song'
import { PlayMode } from '../model/PlayState'
import { TimeUtils } from '../common/utils/TimeUtils'
import { PlayStateKeys, parseSongFromJson } from '../common/GlobalPlayState'
import { PlayController } from '../common/PlayController'
import { PlayQueueService } from '../service/PlayQueueService'
import { PlayQueuePanel } from './PlayQueuePanel'

/**
 * 播放详情面板组件
 * 点击迷你播放器后展开的二级卡片
 * 支持拖拽展开/收起
 */
@Component
export struct PlayerDetailPanel {
  // 使用 @StorageLink 连接全局播放状态
  @StorageLink(PlayStateKeys.CURRENT_SONG) currentSongJson: string = ''
  @StorageLink(PlayStateKeys.IS_PLAYING) @Watch('onPlayingStateChange') isPlaying: boolean = false
  @StorageLink(PlayStateKeys.PLAY_MODE) playMode: number = PlayMode.SEQUENCE
  @StorageLink(PlayStateKeys.CURRENT_POSITION) currentPosition: number = 0

  // 展开状态（由父组件控制）
  @Link isExpanded: boolean

  @State private isFavorite: boolean = false
  @State private isDragging: boolean = false
  @State private dragPosition: number = 0
  @State private coverRotation: number = 0
  @State private panelOffset: number = 0 // 面板偏移量（用于拖拽手势）

  // 播放控制器
  private playController: PlayController = PlayController.getInstance()
  private queueService: PlayQueueService = PlayQueueService.getInstance()
  private rotationTimer: number = -1

  // 面板高度
  private panelHeight: number = 0
  private screenHeight: number = 0

  // 回调
  onClose?: () => void

  // 播放列表弹窗控制器
  private playQueueDialogController: CustomDialogController = new CustomDialogController({
    builder: PlayQueuePanel(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    offset: { dx: 0, dy: 0 }
  })

  aboutToAppear(): void {
    console.info('PlayerDetailPanel', 'aboutToAppear')
    if (this.isPlaying) {
      this.startRotation()
    }
  }

  aboutToDisappear(): void {
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
    }, 16)
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
   * 监听播放状态变化
   */
  onPlayingStateChange(): void {
    if (this.isPlaying) {
      this.startRotation()
    } else {
      this.stopRotation()
    }
  }

  /**
   * 获取当前歌曲对象
   */
  private getCurrentSong(): Song | null {
    return parseSongFromJson(this.currentSongJson)
  }

  /**
   * 判断是否有有效歌曲
   */
  private hasValidSong(): boolean {
    const song = this.getCurrentSong()
    return song !== null && song.title !== undefined && song.title.length > 0
  }

  /**
   * 获取显示标题（处理异常数据）
   */
  private getDisplayTitle(): string {
    const song = this.getCurrentSong()
    if (!song || !song.title || song.title.trim().length === 0) {
      return '等待播放'
    }
    if (song.title === '未知歌曲' || song.title === 'Unknown') {
      return '未命名音乐'
    }
    return song.title
  }

  /**
   * 获取显示艺术家（处理异常数据）
   */
  private getDisplayArtist(): string {
    const song = this.getCurrentSong()
    if (!song || !song.artist || song.artist.trim().length === 0 ||
        song.artist === '未知艺术家' || song.artist === 'Unknown Artist' || song.artist === '<unknown>') {
      return ''
    }
    return song.artist
  }

  /**
   * 获取显示专辑名（处理异常数据）
   */
  private getDisplayAlbum(): string {
    const song = this.getCurrentSong()
    if (!song || !song.album || song.album.trim().length === 0 ||
        song.album === '未知专辑' || song.album === 'Unknown Album' || song.album === '<unknown>') {
      return ''
    }
    return song.album
  }

  /**
   * 判断是否有有效封面
   */
  private hasValidAlbumArt(): boolean {
    const song = this.getCurrentSong()
    return song !== null && song.albumArt !== undefined && song.albumArt !== null && song.albumArt !== ''
  }

  /**
   * 判断是否有有效时长
   */
  private hasValidDuration(): boolean {
    const song = this.getCurrentSong()
    return song !== null && song.duration > 0
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
    console.info('PlayerDetailPanel', `Play mode changed to: ${this.getModeName()}`)
  }

  /**
   * 获取显示的播放位置
   */
  private getDisplayPosition(): number {
    return this.isDragging ? this.dragPosition : this.currentPosition
  }

  /**
   * 获取进度百分比
   */
  private getProgressPercent(): number {
    const song = this.getCurrentSong()
    if (!song || song.duration === 0) {
      return 0
    }
    return (this.getDisplayPosition() / song.duration) * 100
  }

  /**
   * 关闭面板
   */
  private closePanel(): void {
    this.isExpanded = false
    this.onClose?.()
  }

  build() {
    Column() {
      // 顶部拖拽区域
      Column() {
        // 拖拽指示条
        Row()
          .width(40)
          .height(4)
          .borderRadius(2)
          .backgroundColor('rgba(255, 255, 255, 0.5)')
          .margin({ top: 12, bottom: 8 })
      }
      .width('100%')
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionStart(() => {
            console.info('PlayerDetailPanel', 'Pan gesture started')
          })
          .onActionUpdate((event: GestureEvent) => {
            if (event.offsetY > 0) {
              this.panelOffset = event.offsetY
            }
          })
          .onActionEnd((event: GestureEvent) => {
            // 如果向下拖动超过 150px，关闭面板
            if (event.offsetY > 150) {
              this.closePanel()
            }
            this.panelOffset = 0
          })
      )

      // 顶部导航栏
      Row() {
        // 关闭按钮
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
          .rotate({ angle: -90 }) // 向下箭头
          .onClick(() => {
            this.closePanel()
          })

        // 标题区域
        Column() {
          Text('正在播放')
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')

          // 专辑名：有值则显示，无值则显示歌曲名或提示
          if (this.getDisplayAlbum().length > 0) {
            Text(this.getDisplayAlbum())
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          } else if (this.hasValidSong()) {
            Text(this.getDisplayTitle())
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          } else {
            Text('选择歌曲')
              .fontSize(16)
              .fontColor('rgba(255, 255, 255, 0.5)')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 更多按钮
        Image($r('app.media.ic_more'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
          .onClick(() => {
            console.info('PlayerDetailPanel', 'More button clicked')
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

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
    .borderRadius({ topLeft: 20, topRight: 20 })
    .clip(true)
    .translate({ y: this.panelOffset })
    .animation({
      duration: 150,
      curve: Curve.EaseOut
    })
  }

  @Builder
  AlbumCover() {
    Column() {
      // 封面容器 - 带阴影效果和旋转动画
      Stack() {
        // 封面阴影
        Column()
          .width(220)
          .height(220)
          .borderRadius(110)
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .offset({ x: 0, y: 12 })
          .blur(25)

        // 唱片底盘效果
        Circle()
          .width(250)
          .height(250)
          .fill('#1a1a1a')
          .rotate({ angle: this.coverRotation })

        // 唱片纹理
        Circle()
          .width(240)
          .height(240)
          .fill('transparent')
          .stroke('#333333')
          .strokeWidth(1)
          .rotate({ angle: this.coverRotation })

        // 专辑封面（圆形）
        Image(this.getCurrentSong()?.albumArt || $r('app.media.default_album'))
          .width(150)
          .height(150)
          .borderRadius(75)
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
          .width(20)
          .height(20)
          .fill('#222222')
          .rotate({ angle: this.coverRotation })

        Circle()
          .width(6)
          .height(6)
          .fill('#ffffff')
      }
    }
    .width('100%')
    .padding({ top: 20 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SongInfo() {
    Column() {
      // 歌曲名称
      Text(this.getDisplayTitle())
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.hasValidSong() ? '#FFFFFF' : 'rgba(255, 255, 255, 0.5)')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 歌手名称（有值才显示）
      if (this.getDisplayArtist().length > 0) {
        Text(this.getDisplayArtist())
          .fontSize(15)
          .fontColor('rgba(255, 255, 255, 0.7)')
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        // 无艺术家时用较小的占位，保持布局
        Row()
          .height(21) // 15 fontSize + 6 margin
      }

      // 操作按钮行
      Row() {
        // 收藏按钮
        Column() {
          Image($r('app.media.ic_scan'))
            .width(22)
            .height(22)
            .fillColor(this.isFavorite ? '#FF6B6B' : 'rgba(255, 255, 255, 0.6)')
        }
        .onClick(() => {
          this.isFavorite = !this.isFavorite
        })

        // 下载按钮
        Column() {
          Image($r('app.media.ic_scan'))
            .width(22)
            .height(22)
            .fillColor('rgba(255, 255, 255, 0.6)')
        }
        .margin({ left: 28 })

        // 评论按钮
        Column() {
          Image($r('app.media.ic_more'))
            .width(22)
            .height(22)
            .fillColor('rgba(255, 255, 255, 0.6)')
        }
        .margin({ left: 28 })

        // 分享按钮
        Column() {
          Image($r('app.media.ic_search'))
            .width(22)
            .height(22)
            .fillColor('rgba(255, 255, 255, 0.6)')
        }
        .margin({ left: 28 })
      }
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ left: 28, right: 28 })
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
            } else if (mode === SliderChangeMode.Moving) {
              this.dragPosition = newPosition
            } else if (mode === SliderChangeMode.End) {
              this.isDragging = false
              this.playController.seekTo(newPosition)
            } else if (mode === SliderChangeMode.Click) {
              this.playController.seekTo(newPosition)
            }
          }
        })

      // 时间显示
      Row() {
        // 当前播放时间
        Text(this.hasValidDuration() ? TimeUtils.formatDuration(this.getDisplayPosition()) : '--:--')
          .fontSize(11)
          .fontColor('rgba(255, 255, 255, 0.6)')

        Blank()

        // 总时长
        Text(this.hasValidDuration() ? TimeUtils.formatDuration(this.getCurrentSong()?.duration || 0) : '--:--')
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

  @Builder
  ControlButtons() {
    Column() {
      // 主控制按钮行
      Row() {
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

        Blank()

        // 上一首
        Image($r('app.media.ic_previous'))
          .width(32)
          .height(32)
          .fillColor('#FFFFFF')
          .onClick(() => {
            this.playController.playPrevious()
          })

        // 播放/暂停按钮
        Stack() {
          Circle()
            .width(64)
            .height(64)
            .fill('#FFFFFF')

          Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(28)
            .height(28)
            .fillColor('#764ba2')
        }
        .margin({ left: 24, right: 24 })
        .onClick(() => {
          this.playController.togglePlayPause()
        })

        // 下一首
        Image($r('app.media.ic_next'))
          .width(32)
          .height(32)
          .fillColor('#FFFFFF')
          .onClick(() => {
            this.playController.playNext()
          })

        Blank()

        // 播放列表按钮
        Column() {
          Image($r('app.media.ic_playlist'))
            .width(24)
            .height(24)
            .fillColor('rgba(255, 255, 255, 0.8)')
        }
        .onClick(() => {
          this.playQueueDialogController.open()
        })
      }
      .width('100%')
      .padding({ left: 28, right: 28 })
      .alignItems(VerticalAlign.Center)

      // 播放模式提示
      Text(this.getModeName())
        .fontSize(10)
        .fontColor('rgba(255, 255, 255, 0.5)')
        .margin({ top: 12 })
    }
    .width('100%')
  }
}
