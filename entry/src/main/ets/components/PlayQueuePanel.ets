import { Song } from '../model/Song'
import { PlayMode } from '../model/PlayState'
import { PlayQueueService } from '../service/PlayQueueService'
import { PlayStateKeys } from '../common/GlobalPlayState'

/**
 * 播放队列弹窗组件
 * 显示当前播放队列，支持切歌、删除、切换播放模式
 */
@CustomDialog
export struct PlayQueuePanel {
  controller: CustomDialogController
  private queueService: PlayQueueService = PlayQueueService.getInstance()

  @State private queue: Song[] = []
  @State private currentIndex: number = -1
  @State private playMode: PlayMode = PlayMode.SEQUENCE

  // 从全局状态获取播放模式
  @StorageLink(PlayStateKeys.PLAY_MODE) storedPlayMode: number = PlayMode.SEQUENCE

  aboutToAppear(): void {
    this.queue = this.queueService.getQueue()
    this.currentIndex = this.queueService.getCurrentIndex()
    this.playMode = this.queueService.getPlayMode()
  }

  /**
   * 获取播放模式名称
   */
  private getPlayModeName(): string {
    return this.queueService.getPlayModeName(this.playMode)
  }

  /**
   * 获取播放模式图标
   */
  private getPlayModeIcon(): Resource {
    switch (this.playMode) {
      case PlayMode.LOOP:
        return $r('app.media.ic_mode_loop')
      case PlayMode.SINGLE:
        return $r('app.media.ic_mode_single')
      case PlayMode.SHUFFLE:
        return $r('app.media.ic_mode_shuffle')
      case PlayMode.SEQUENCE:
      default:
        return $r('app.media.ic_mode_sequence')
    }
  }

  /**
   * 切换播放模式
   */
  private async togglePlayMode(): Promise<void> {
    this.playMode = await this.queueService.togglePlayMode()
  }

  /**
   * 播放指定歌曲
   */
  private async playSongAtIndex(index: number): Promise<void> {
    await this.queueService.playAtIndex(index)
    this.currentIndex = index
  }

  /**
   * 删除指定歌曲
   */
  private removeSongAtIndex(index: number): void {
    this.queueService.removeFromQueue(index)
    this.queue = this.queueService.getQueue()
    this.currentIndex = this.queueService.getCurrentIndex()
  }

  /**
   * 清空队列
   */
  private clearQueue(): void {
    this.queueService.clearQueue()
    this.queue = []
    this.currentIndex = -1
  }

  /**
   * 格式化时长
   */
  private formatDuration(ms: number): string {
    if (ms <= 0) {
      return '0:00'
    }
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('播放队列')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        // 播放模式切换
        Row() {
          Image(this.getPlayModeIcon())
            .width(20)
            .height(20)
            .fillColor('#666666')

          Text(this.getPlayModeName())
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(16)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          this.togglePlayMode()
        })

        // 关闭按钮
        Image($r('app.media.ic_close'))
          .width(24)
          .height(24)
          .fillColor('#999999')
          .margin({ left: 16 })
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      // 队列信息栏
      Row() {
        Text(`共 ${this.queue.length} 首`)
          .fontSize(13)
          .fontColor('#999999')

        Blank()

        // 清空按钮
        if (this.queue.length > 0) {
          Row() {
            Image($r('app.media.ic_delete'))
              .width(14)
              .height(14)
              .fillColor('#999999')

            Text('清空')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ left: 4 })
          }
          .onClick(() => {
            this.clearQueue()
          })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 8 })

      // 分隔线
      Divider()
        .width('100%')
        .height(0.5)
        .color('#E0E0E0')

      // 歌曲列表
      if (this.queue.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.ic_empty'))
            .width(60)
            .height(60)
            .fillColor('#CCCCCC')

          Text('播放队列为空')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.queue, (song: Song, index: number) => {
            ListItem() {
              this.QueueItem(song, index)
            }
          }, (song: Song, index: number) => `${song.id}_${index}`)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 56, endMargin: 16 })
      }
    }
    .width('100%')
    .height('60%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  QueueItem(song: Song, index: number) {
    Row() {
      // 序号或播放指示
      if (index === this.currentIndex) {
        Image($r('app.media.ic_playing'))
          .width(20)
          .height(20)
          .fillColor('#007AFF')
      } else {
        Text(`${index + 1}`)
          .fontSize(14)
          .fontColor('#CCCCCC')
          .width(20)
          .textAlign(TextAlign.Center)
      }

      // 歌曲信息
      Column() {
        Text(song.title)
          .fontSize(15)
          .fontColor(index === this.currentIndex ? '#007AFF' : '#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(song.artist)
          .fontSize(12)
          .fontColor(index === this.currentIndex ? '#66B3FF' : '#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 时长
      Text(this.formatDuration(song.duration))
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ right: 8 })

      // 删除按钮
      Image($r('app.media.ic_close'))
        .width(18)
        .height(18)
        .fillColor('#CCCCCC')
        .onClick(() => {
          this.removeSongAtIndex(index)
        })
        .hitTestBehavior(HitTestMode.Block)
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 16 })
    .backgroundColor(index === this.currentIndex ? '#F8F8FF' : '#FFFFFF')
    .onClick(() => {
      this.playSongAtIndex(index)
    })
  }
}

/**
 * 播放队列弹窗控制器工厂
 */
export function createPlayQueuePanelController(): CustomDialogController {
  return new CustomDialogController({
    builder: PlayQueuePanel(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    offset: { dx: 0, dy: 0 }
  })
}
