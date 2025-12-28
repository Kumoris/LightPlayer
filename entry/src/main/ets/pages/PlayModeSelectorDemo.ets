import { PlayMode } from '../model/PlayState'
import { PlayModeSelector } from '../components/PlayModeSelector'

/**
 * 播放模式选择示例页面
 * 演示如何集成播放模式选择器
 */
@Entry
@Component
struct PlayModeSelectorDemo {
  @State currentMode: PlayMode = PlayMode.SEQUENCE
  @State modeName: string = '顺序播放'
  private dialogController: CustomDialogController | null = null

  build() {
    Column() {
      // 标题
      Text('播放模式选择器示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })

      // 当前模式显示
      Column() {
        Text('当前模式')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Text(this.modeName)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#007AFF')

        Text(`PlayMode 值: ${this.currentMode}`)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F8F8F8')
      .borderRadius(12)
      .margin({ bottom: 20 })

      // 打开选择器按钮
      Button('选择播放模式')
        .fontSize(16)
        .width('100%')
        .height(50)
        .backgroundColor('#007AFF')
        .onClick(() => {
          this.showModeSelector()
        })

      // 说明文字
      Text('点击按钮查看所有6种播放模式')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 16 })

      Blank()

      // 模式列表
      Text('所有可用模式:')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      Column({ space: 8 }) {
        this.ModeListItem('顺序播放', 'SEQUENCE')
        this.ModeListItem('列表循环', 'LOOP')
        this.ModeListItem('单曲循环', 'SINGLE')
        this.ModeListItem('智能随机 🆕', 'SMART_SHUFFLE')
        this.ModeListItem('时间感知 🆕', 'TIME_AWARE')
        this.ModeListItem('夜间模式 🆕', 'NIGHT_MODE')
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ModeListItem(name: string, mode: string) {
    Row() {
      Text('•')
        .fontSize(20)
        .fontColor('#007AFF')
        .margin({ right: 8 })

      Text(name)
        .fontSize(14)
        .fontColor('#333333')
    }
  }

  /**
   * 显示播放模式选择器
   */
  showModeSelector(): void {
    this.dialogController = new CustomDialogController({
      builder: PlayModeSelector({
        currentMode: this.currentMode,
        onModeSelected: (mode: PlayMode) => {
          this.currentMode = mode
          this.updateModeName(mode)
        }
      }),
      customStyle: true,
      alignment: DialogAlignment.Bottom
    })

    this.dialogController.open()
  }

  /**
   * 更新模式名称
   */
  updateModeName(mode: PlayMode): void {
    switch (mode) {
      case PlayMode.SEQUENCE:
        this.modeName = '顺序播放'
        break
      case PlayMode.LOOP:
        this.modeName = '列表循环'
        break
      case PlayMode.SINGLE:
        this.modeName = '单曲循环'
        break
      case PlayMode.SMART_SHUFFLE:
        this.modeName = '智能随机'
        break
      case PlayMode.TIME_AWARE:
        this.modeName = '时间感知'
        break
      case PlayMode.NIGHT_MODE:
        this.modeName = '夜间模式'
        break
      default:
        this.modeName = '未知模式'
    }
  }
}
