import { Song } from '../model/Song'
import { parseSongFromJson } from '../common/GlobalPlayState'

/**
 * 迷你播放器组件（底部悬浮）
 * 固定在页面底部，包含封面、歌曲信息、进度条、时间显示、播放控制按钮
 * 设计理念：持续可感知的播放状态，而非仅是按钮集合
 */
@Component
export struct MiniPlayer {
  // 接受 JSON 字符串形式的歌曲数据，便于与 @StorageLink 配合
  @Prop currentSongJson: string = ''
  @Prop isPlaying: boolean = false
  @Prop progress: number = 0 // 0-100
  @Prop currentPosition: number = 0 // 当前播放位置（毫秒）
  @Prop duration: number = 0 // 总时长（毫秒）
  @State isPressed: boolean = false
  @State isNextPressed: boolean = false
  @State isPlaylistPressed: boolean = false
  @State isDragging: boolean = false // 是否正在拖动进度条
  @State dragProgress: number = 0 // 拖动时的进度值
  onPlayPauseClick?: () => void
  onNextClick?: () => void
  onPlayerClick?: () => void
  onPlaylistClick?: () => void
  onSeek?: (position: number) => void // 拖动进度条回调

  /**
   * 获取当前歌曲对象
   */
  private getCurrentSong(): Song | null {
    return parseSongFromJson(this.currentSongJson)
  }

  /**
   * 判断是否有有效歌曲数据
   */
  private hasValidSong(): boolean {
    const song = this.getCurrentSong()
    return song !== null && song.title !== undefined && song.title.length > 0
  }

  /**
   * 判断是否有有效的时长数据
   */
  private hasValidDuration(): boolean {
    return this.duration > 0 && this.hasValidSong()
  }

  /**
   * 获取显示标题（处理异常数据）
   */
  private getDisplayTitle(): string {
    const song = this.getCurrentSong()
    if (!song || !song.title || song.title.trim().length === 0) {
      return '选择歌曲开始播放'
    }
    // 过滤掉 "未知" 类占位符
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
    if (!song) {
      return '从音乐库中选择'
    }
    if (!song.artist || song.artist.trim().length === 0 ||
        song.artist === '未知艺术家' || song.artist === 'Unknown Artist' || song.artist === '<unknown>') {
      return '' // 返回空，不显示无意义信息
    }
    return song.artist
  }

  /**
   * 判断是否有有效封面
   */
  private hasValidAlbumArt(): boolean {
    const song = this.getCurrentSong()
    return song !== null && song.albumArt !== undefined && song.albumArt !== null && song.albumArt !== ''
  }

  /**
   * 格式化时间显示 (毫秒 -> mm:ss)
   */
  private formatTime(ms: number): string {
    if (ms <= 0) return '--:--'
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 获取显示的进度（拖动时用拖动值，否则用实际进度）
   */
  private getDisplayProgress(): number {
    return this.isDragging ? this.dragProgress : this.progress
  }

  build() {
    Column() {
      // 主内容区域（可点击展开全屏播放页）
      Row() {
        // 专辑封面 - 带圆角和阴影
        Stack() {
          Image(this.getCurrentSong()?.albumArt || $r('app.media.default_album'))
            .width(44)
            .height(44)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)

          // 无封面时显示灰色蒙层 + 播放图标提示
          if (!this.hasValidAlbumArt()) {
            Column() {
              Image($r('app.media.ic_playing'))
                .width(20)
                .height(20)
                .fillColor('rgba(255, 255, 255, 0.7)')
            }
            .width(44)
            .height(44)
            .borderRadius(6)
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .justifyContent(FlexAlign.Center)
          }

          // 播放中动画指示
          if (this.isPlaying && this.hasValidSong()) {
            Column()
              .width(44)
              .height(44)
              .borderRadius(6)
              .backgroundColor('rgba(0, 122, 255, 0.08)')
          }
        }
        .margin({ left: 12 })
        .onClick(() => {
          console.info('MiniPlayer', 'Album art clicked - expand player')
          this.onPlayerClick?.()
        })

        // 歌曲信息 + 时间显示
        Column() {
          // 歌曲标题
          Text(this.getDisplayTitle())
            .fontSize(14)
            .fontColor(this.hasValidSong() ? '#333333' : '#999999')
            .fontWeight(this.hasValidSong() ? FontWeight.Medium : FontWeight.Normal)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          // 艺术家 + 时间信息
          Row() {
            // 播放中指示器（仅在有效播放时显示）
            if (this.isPlaying && this.hasValidSong()) {
              Row() {
                ForEach([1, 2, 3], (item: number) => {
                  Column()
                    .width(2.5)
                    .height(item === 2 ? 9 : 5)
                    .backgroundColor('#007AFF')
                    .borderRadius(1)
                    .margin({ right: 1.5 })
                })
              }
              .margin({ right: 5 })
            }

            // 艺术家名（有值才显示，避免显示"未知艺术家"）
            if (this.getDisplayArtist().length > 0) {
              Text(this.getDisplayArtist())
                .fontSize(11)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            } else if (!this.hasValidSong()) {
              // 无歌曲时显示引导文案
              Text('从音乐库中选择')
                .fontSize(11)
                .fontColor('#AAAAAA')
                .maxLines(1)
                .layoutWeight(1)
            } else {
              // 有歌曲但无艺术家，留空
              Blank()
                .layoutWeight(1)
            }

            // 时间显示：仅在有有效时长时显示
            if (this.hasValidDuration()) {
              Text(`${this.formatTime(this.isDragging ? (this.dragProgress / 100 * this.duration) : this.currentPosition)} / ${this.formatTime(this.duration)}`)
                .fontSize(10)
                .fontColor('#007AFF')
                .fontWeight(FontWeight.Medium)
            }
          }
          .width('100%')
          .margin({ top: 3 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10, right: 8 })
        .onClick(() => {
          console.info('MiniPlayer', 'Song info area clicked - navigate to player')
          this.onPlayerClick?.()
        })

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
          console.info('MiniPlayer', `Play/Pause button clicked, current state: ${this.isPlaying}`)
          this.onPlayPauseClick?.()
        })

        // 下一首按钮
        Image($r('app.media.ic_next'))
          .width(22)
          .height(22)
          .fillColor(this.isNextPressed ? '#333333' : '#666666')
          .margin({ left: 6 })
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.isNextPressed = true
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.isNextPressed = false
            }
          })
          .onClick(() => {
            console.info('MiniPlayer', 'Next button clicked')
            this.onNextClick?.()
          })

        // 播放列表按钮
        Image($r('app.media.ic_playlist'))
          .width(20)
          .height(20)
          .fillColor(this.isPlaylistPressed ? '#333333' : '#666666')
          .margin({ left: 6, right: 10 })
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.isPlaylistPressed = true
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.isPlaylistPressed = false
            }
          })
          .onClick(() => {
            console.info('MiniPlayer', 'Playlist button clicked')
            this.onPlaylistClick?.()
          })
      }
      .width('100%')
      .height(52)
      .alignItems(VerticalAlign.Center)

      // 可拖动进度条
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
              console.info('MiniPlayer', `Seek to position: ${targetPosition}ms (${value}%)`)
              this.onSeek?.(targetPosition)
            }
          })
          .width('100%')
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .height(20)
    }
    .width('100%')
    .height(72)
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 16,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: -4
    })
  }
}
