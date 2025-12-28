import { Song } from '../model/Song'
import { SongMetadata } from '../service/MetadataExtractor'

/**
 * 元数据编辑对话框组件
 * 允许用户手动编辑歌曲的流派、BPM、能量和情绪
 */
@CustomDialog
export struct MetadataEditorDialog {
  controller: CustomDialogController
  @State song: Song | null = null
  @State genre: string = ''
  @State bpm: number = 120
  @State energy: number = 50
  @State mood: string = ''
  onSave?: (metadata: SongMetadata) => void

  // 预定义选项
  private readonly GENRE_OPTIONS: string[] = [
    '流行', '摇滚', '电子', '古典', '爵士',
    '嘻哈', '民谣', 'R&B', '轻音乐', '舞曲'
  ]

  private readonly MOOD_OPTIONS: string[] = [
    '快乐', '悲伤', '平静', '激动', '浪漫', '放松'
  ]

  aboutToAppear(): void {
    if (this.song) {
      this.genre = this.song.genre || '流行'
      this.bpm = this.song.bpm || 120
      this.energy = this.song.energy || 50
      this.mood = this.song.mood || '轻松'
    }
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('编辑歌曲元数据')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .padding({ top: 20, bottom: 10, left: 24, right: 24 })

      // 歌曲信息
      if (this.song) {
        Column() {
          Text(this.song.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.song.artist)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 24, right: 24, bottom: 16 })
      }

      Divider()

      // 编辑表单
      Scroll() {
        Column({ space: 20 }) {
          // 流派选择
          Column({ space: 8 }) {
            Text('流派')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.GENRE_OPTIONS, (genreOption: string) => {
                Text(genreOption)
                  .fontSize(14)
                  .fontColor(this.genre === genreOption ? '#FFFFFF' : '#333333')
                  .backgroundColor(this.genre === genreOption ? '#007AFF' : '#F0F0F0')
                  .borderRadius(16)
                  .padding({ top: 6, bottom: 6, left: 16, right: 16 })
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.genre = genreOption
                  })
              })
            }
          }
          .alignItems(HorizontalAlign.Start)

          // BPM 调节
          Column({ space: 8 }) {
            Row() {
              Text('节奏 (BPM)')
                .fontSize(14)
                .fontColor('#666666')

              Blank()

              Text(`${this.bpm}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#007AFF')
            }
            .width('100%')

            Slider({
              value: this.bpm,
              min: 60,
              max: 180,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#007AFF')
              .trackColor('#E0E0E0')
              .selectedColor('#007AFF')
              .onChange((value: number) => {
                this.bpm = Math.round(value)
              })
          }

          // 能量等级调节
          Column({ space: 8 }) {
            Row() {
              Text('能量等级')
                .fontSize(14)
                .fontColor('#666666')

              Blank()

              Text(`${this.energy}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#007AFF')
            }
            .width('100%')

            Slider({
              value: this.energy,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .blockColor('#007AFF')
              .trackColor('#E0E0E0')
              .selectedColor('#007AFF')
              .onChange((value: number) => {
                this.energy = Math.round(value)
              })

            // 能量等级说明
            Text(this.getEnergyDescription())
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
          }

          // 情绪选择
          Column({ space: 8 }) {
            Text('情绪')
              .fontSize(14)
              .fontColor('#666666')
              .width('100%')

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.MOOD_OPTIONS, (moodOption: string) => {
                Text(moodOption)
                  .fontSize(14)
                  .fontColor(this.mood === moodOption ? '#FFFFFF' : '#333333')
                  .backgroundColor(this.mood === moodOption ? '#007AFF' : '#F0F0F0')
                  .borderRadius(16)
                  .padding({ top: 6, bottom: 6, left: 16, right: 16 })
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.mood = moodOption
                  })
              })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: 24, right: 24, top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      Divider()

      // 按钮
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F0F0F0')
          .layoutWeight(1)
          .onClick(() => {
            this.controller.close()
          })

        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            const metadata: SongMetadata = {
              genre: this.genre,
              bpm: this.bpm,
              energy: this.energy,
              mood: this.mood
            }
            this.onSave?.(metadata)
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 16 })
    }
    .width('100%')
    .height('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  /**
   * 获取能量等级描述
   */
  private getEnergyDescription(): string {
    if (this.energy >= 80) {
      return '⚡ 极高能量 - 激烈、狂热、高强度'
    } else if (this.energy >= 60) {
      return '🔥 高能量 - 充满活力、节奏强劲'
    } else if (this.energy >= 40) {
      return '☀️ 中等能量 - 轻快、愉悦、适中'
    } else if (this.energy >= 20) {
      return '🌙 低能量 - 舒缓、温柔、放松'
    } else {
      return '💤 极低能量 - 安静、平和、冥想'
    }
  }
}
