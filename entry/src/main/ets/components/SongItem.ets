import { Song } from '../model/Song'
import { TimeUtils } from '../common/utils/TimeUtils'

/**
 * 歌曲列表项组件
 */
@Component
export struct SongItem {
  @Prop song: Song = new Song()
  @Prop isPlaying: boolean = false
  onItemClick?: (song: Song) => void
  onMoreClick?: (song: Song) => void

  build() {
    Row() {
      // 专辑封面
      Stack() {
        Image(this.song.albumArt || $r('app.media.default_album'))
          .width(48)
          .height(48)
          .borderRadius(4)
          .objectFit(ImageFit.Cover)

        if (this.isPlaying) {
          Column() {
            Image($r('app.media.ic_playing'))
              .width(24)
              .height(24)
              .fillColor('#007AFF')
          }
          .width(48)
          .height(48)
          .backgroundColor('rgba(0,0,0,0.3)')
          .borderRadius(4)
          .justifyContent(FlexAlign.Center)
        }
      }

      // 歌曲信息
      Column() {
        Text(this.song.title)
          .fontSize(16)
          .fontColor(this.isPlaying ? '#007AFF' : '#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(`${this.song.artist} - ${this.song.album}`)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
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

      // 更多按钮
      Image($r('app.media.ic_more'))
        .width(24)
        .height(24)
        .fillColor('#999999')
        .onClick(() => {
          this.onMoreClick?.(this.song)
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.onItemClick?.(this.song)
    })
  }
}
