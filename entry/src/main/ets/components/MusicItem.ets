import { Song } from '../model/Song'
import { TimeUtils } from '../common/utils/TimeUtils'

/**
 * 音乐列表项组件
 * 包含：封面图、歌曲名、歌手名、时长
 * 支持点击高亮效果和多选模式
 */
@Component
export struct MusicItem {
  @Prop song: Song = new Song()
  @Prop isPlaying: boolean = false
  @Prop index: number = 0
  @Prop isSelectMode: boolean = false  // 多选模式
  @Prop isSelected: boolean = false    // 是否被选中
  @State isPressed: boolean = false
  onItemClick?: (song: Song, index: number) => void
  onMoreClick?: (song: Song) => void
  onSelectChange?: (song: Song, index: number, selected: boolean) => void

  build() {
    Row() {
      // 多选模式下显示复选框
      if (this.isSelectMode) {
        Checkbox()
          .select(this.isSelected)
          .selectedColor('#007AFF')
          .width(20)
          .height(20)
          .onChange((checked: boolean) => {
            this.onSelectChange?.(this.song, this.index, checked)
          })
      } else {
        // 序号或播放中指示
        if (this.isPlaying) {
          Image($r('app.media.ic_playing'))
            .width(24)
            .height(24)
            .fillColor('#007AFF')
        } else {
          Text(`${this.index + 1}`)
            .fontSize(14)
            .fontColor('#999999')
            .width(24)
            .textAlign(TextAlign.Center)
        }
      }

      // 专辑封面 - 优化图片加载
      Stack() {
        Image(this.song.albumArt || $r('app.media.default_album'))
          .width(48)
          .height(48)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .autoResize(true)
          .interpolation(ImageInterpolation.Medium)
          .renderMode(ImageRenderMode.Original)

        // 播放中遮罩
        if (this.isPlaying && !this.isSelectMode) {
          Column()
            .width(48)
            .height(48)
            .borderRadius(6)
            .backgroundColor('rgba(0, 122, 255, 0.15)')
        }

        // 选中状态遮罩
        if (this.isSelectMode && this.isSelected) {
          Column()
            .width(48)
            .height(48)
            .borderRadius(6)
            .backgroundColor('rgba(0, 122, 255, 0.2)')
        }
      }
      .margin({ left: 12 })

      // 歌曲信息
      Column() {
        Text(this.song.title)
          .fontSize(16)
          .fontColor(this.isPlaying ? '#007AFF' : (this.isSelected ? '#007AFF' : '#333333'))
          .fontWeight(this.isPlaying ? FontWeight.Medium : FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          // SQ 标识（如果是高品质）
          if (this.song.mimeType === 'audio/flac' || this.song.size > 10000000) {
            Text('SQ')
              .fontSize(9)
              .fontColor('#FF6B00')
              .borderWidth(1)
              .borderColor('#FF6B00')
              .borderRadius(2)
              .padding({ left: 3, right: 3, top: 1, bottom: 1 })
              .margin({ right: 6 })
          }

          Text(`${this.song.artist}`)
            .fontSize(12)
            .fontColor('#999999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(` - ${this.song.album}`)
            .fontSize(12)
            .fontColor('#BBBBBB')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: '40%' })
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 时长
      Text(TimeUtils.formatDuration(this.song.duration))
        .fontSize(12)
        .fontColor('#999999')
        .margin({ right: 8 })

      // 更多按钮（非多选模式下显示）
      if (!this.isSelectMode) {
        Image($r('app.media.ic_more'))
          .width(24)
          .height(24)
          .fillColor('#CCCCCC')
          .onClick(() => {
            console.info('MusicItem', `More button clicked for: ${this.song.title}`)
            this.onMoreClick?.(this.song)
          })
      }
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isPressed ? '#F5F5F5' : (this.isSelected && this.isSelectMode ? '#F0F7FF' : '#FFFFFF'))
    .animation({
      duration: 150,
      curve: Curve.EaseOut
    })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
    .onClick(() => {
      if (this.isSelectMode) {
        // 多选模式下切换选中状态
        this.onSelectChange?.(this.song, this.index, !this.isSelected)
      } else {
        console.info('MusicItem', `Item clicked: ${this.song.title} at index ${this.index}`)
        this.onItemClick?.(this.song, this.index)
      }
    })
  }
}
