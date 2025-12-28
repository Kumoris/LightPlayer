import { PlayMode } from '../model/PlayState'

/**
 * 播放模式信息
 */
interface PlayModeItem {
  mode: PlayMode
  name: string
  icon: string
  description: string
  color: string
}

/**
 * 播放模式选择器面板
 * 显示所有7种播放模式，用户可直接选择
 */
@CustomDialog
export struct PlayModeSelector {
  controller: CustomDialogController
  @Prop currentMode: PlayMode = PlayMode.SEQUENCE
  onModeSelected?: (mode: PlayMode) => void

  private readonly PLAY_MODES: PlayModeItem[] = [
    {
      mode: PlayMode.SEQUENCE,
      name: '顺序播放',
      icon: '▶️',
      description: '按照列表顺序依次播放',
      color: '#007AFF'
    },
    {
      mode: PlayMode.LOOP,
      name: '列表循环',
      icon: '🔁',
      description: '播放完列表后重新开始',
      color: '#34C759'
    },
    {
      mode: PlayMode.SINGLE,
      name: '单曲循环',
      icon: '🔂',
      description: '重复播放当前歌曲',
      color: '#FF9500'
    },
    {
      mode: PlayMode.SMART_SHUFFLE,
      name: '智能随机',
      icon: '🧠',
      description: '避免同流派/专辑连续播放',
      color: '#AF52DE'
    },
    {
      mode: PlayMode.TIME_AWARE,
      name: '时间感知',
      icon: '🕒',
      description: '根据时段智能选择歌曲',
      color: '#5856D6'
    },
    {
      mode: PlayMode.NIGHT_MODE,
      name: '夜间模式',
      icon: '🌙',
      description: '舒缓音乐，音量渐弱',
      color: '#5AC8FA'
    }
  ]

  build() {
    Column() {
      // 标题
      Row() {
        Text('选择播放模式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        // 关闭按钮
        Text('✕')
          .fontSize(24)
          .fontColor('#999999')
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 16 })

      Divider()

      // 模式列表
      List({ space: 0 }) {
        ForEach(this.PLAY_MODES, (item: PlayModeItem) => {
          ListItem() {
            this.PlayModeItem(item)
          }
        })
      }
      .layoutWeight(1)
      .divider({
        strokeWidth: 1,
        color: '#F0F0F0',
        startMargin: 20,
        endMargin: 20
      })

      // 提示信息
      Row() {
        Text('💡 提示')
          .fontSize(12)
          .fontColor('#999999')

        Text('智能模式需要歌曲元数据支持')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 16 })
      .backgroundColor('#F8F8F8')
    }
    .width('100%')
    .height('70%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  /**
   * 播放模式选项
   */
  @Builder
  PlayModeItem(item: PlayModeItem) {
    Row() {
      // 图标
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .fill(this.currentMode === item.mode ? item.color : '#F0F0F0')

        Text(item.icon)
          .fontSize(24)
      }
      .margin({ right: 16 })

      // 文字信息
      Column({ space: 4 }) {
        Row() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          // 当前使用标记
          if (this.currentMode === item.mode) {
            Text('使用中')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor(item.color)
              .borderRadius(10)
              .padding({ top: 2, bottom: 2, left: 8, right: 8 })
              .margin({ left: 8 })
          }

          // 新功能标记
          if (item.mode === PlayMode.SMART_SHUFFLE ||
              item.mode === PlayMode.TIME_AWARE ||
              item.mode === PlayMode.NIGHT_MODE) {
            Text('NEW')
              .fontSize(10)
              .fontColor('#FF3B30')
              .fontWeight(FontWeight.Bold)
              .border({ width: 1, color: '#FF3B30', radius: 8 })
              .padding({ top: 1, bottom: 1, left: 6, right: 6 })
              .margin({ left: 6 })
          }
        }

        Text(item.description)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 选择指示器
      if (this.currentMode === item.mode) {
        Text('✓')
          .fontSize(24)
          .fontColor(item.color)
          .fontWeight(FontWeight.Bold)
      } else {
        Text('›')
          .fontSize(24)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .backgroundColor(this.currentMode === item.mode ? '#F8F9FA' : '#FFFFFF')
    .onClick(() => {
      this.onModeSelected?.(item.mode)
      this.controller.close()
    })
  }
}
