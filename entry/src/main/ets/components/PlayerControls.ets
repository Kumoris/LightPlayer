import { Song } from '../model/Song'
import { PlayMode } from '../model/PlayState'
import { TimeUtils } from '../common/utils/TimeUtils'

/**
 * 播放控制组件
 */
@Component
export struct PlayerControls {
  @Prop isPlaying: boolean = false
  @Prop playMode: PlayMode = PlayMode.SEQUENCE
  @Prop currentPosition: number = 0
  @Prop duration: number = 0
  onPlayPauseClick?: () => void
  onPreviousClick?: () => void
  onNextClick?: () => void
  onModeClick?: () => void
  onPlaylistClick?: () => void
  onSeek?: (position: number) => void

  build() {
    Column() {
      // 进度条
      Column() {
        Slider({
          value: this.duration > 0 ? (this.currentPosition / this.duration) * 100 : 0,
          min: 0,
          max: 100,
          style: SliderStyle.OutSet
        })
          .blockColor('#007AFF')
          .trackColor('#E0E0E0')
          .selectedColor('#007AFF')
          .width('100%')
          .onChange((value: number) => {
            const position = (value / 100) * this.duration
            this.onSeek?.(position)
          })

        Row() {
          Text(TimeUtils.formatDuration(this.currentPosition))
            .fontSize(12)
            .fontColor('#999999')

          Blank()

          Text(TimeUtils.formatDuration(this.duration))
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 4, right: 4 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      // 控制按钮
      Row() {
        // 播放模式
        Image(this.getModeIcon())
          .width(28)
          .height(28)
          .fillColor('#666666')
          .onClick(() => {
            this.onModeClick?.()
          })

        Blank()

        // 上一首
        Image($r('app.media.ic_previous'))
          .width(40)
          .height(40)
          .fillColor('#333333')
          .onClick(() => {
            this.onPreviousClick?.()
          })

        // 播放/暂停
        Stack() {
          Circle()
            .width(64)
            .height(64)
            .fill('#007AFF')

          Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(32)
            .height(32)
            .fillColor('#FFFFFF')
        }
        .margin({ left: 24, right: 24 })
        .onClick(() => {
          this.onPlayPauseClick?.()
        })

        // 下一首
        Image($r('app.media.ic_next'))
          .width(40)
          .height(40)
          .fillColor('#333333')
          .onClick(() => {
            this.onNextClick?.()
          })

        Blank()

        // 播放列表
        Image($r('app.media.ic_playlist'))
          .width(28)
          .height(28)
          .fillColor('#666666')
          .onClick(() => {
            this.onPlaylistClick?.()
          })
      }
      .width('100%')
      .padding({ left: 32, right: 32, top: 20, bottom: 20 })
    }
    .width('100%')
  }

  getModeIcon(): Resource {
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
}
