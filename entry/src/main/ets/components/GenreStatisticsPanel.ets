import { GenreStatistic, MusicStatisticsService } from '../service/MusicStatisticsService'
import { Song } from '../model/Song'

/**
 * 流派统计面板组件
 * 显示音乐库的流派分布和统计信息
 */
@Component
export struct GenreStatisticsPanel {
  @Prop songs: Song[] = []
  @State statistics: GenreStatistic[] = []
  @State totalSongs: number = 0
  @State averageEnergy: number = 50
  @State averageBPM: number = 120
  private statisticsService: MusicStatisticsService = MusicStatisticsService.getInstance()

  aboutToAppear(): void {
    this.updateStatistics()
  }

  /**
   * 更新统计数据
   */
  updateStatistics(): void {
    this.statistics = this.statisticsService.calculateGenreStatistics(this.songs)
    this.totalSongs = this.songs.length
    this.averageEnergy = this.statisticsService.getAverageEnergy(this.songs)
    this.averageBPM = this.statisticsService.getAverageBPM(this.songs)
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('音乐库统计')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text(`共 ${this.totalSongs} 首`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })

      // 整体统计卡片
      Row() {
        // 平均能量
        Column() {
          Text('平均能量')
            .fontSize(12)
            .fontColor('#999999')

          Text(`${this.averageEnergy}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007AFF')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Divider()
          .vertical(true)
          .height(40)
          .color('#E0E0E0')

        // 平均BPM
        Column() {
          Text('平均节奏')
            .fontSize(12)
            .fontColor('#999999')

          Text(`${this.averageBPM}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9500')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Divider()
          .vertical(true)
          .height(40)
          .color('#E0E0E0')

        // 流派数量
        Column() {
          Text('流派数')
            .fontSize(12)
            .fontColor('#999999')

          Text(`${this.statistics.length}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#34C759')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor('#F8F8F8')
      .borderRadius(12)
      .margin({ left: 20, right: 20, bottom: 16 })

      // 流派分布标题
      Text('流派分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 8 })

      // 流派列表
      List({ space: 8 }) {
        ForEach(this.statistics, (stat: GenreStatistic, index: number) => {
          ListItem() {
            this.GenreStatItem(stat, index)
          }
        })
      }
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 流派统计项
   */
  @Builder
  GenreStatItem(stat: GenreStatistic, index: number) {
    Row() {
      // 排名
      Text(`${index + 1}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getRankColor(index))
        .width(30)

      // 流派信息
      Column({ space: 4 }) {
        Row() {
          Text(stat.genre)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Blank()

          Text(`${stat.count} 首`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .width('100%')

        // 进度条
        Stack({ alignContent: Alignment.Start }) {
          // 背景
          Row()
            .width('100%')
            .height(6)
            .backgroundColor('#E0E0E0')
            .borderRadius(3)

          // 进度
          Row()
            .width(`${stat.percentage}%`)
            .height(6)
            .backgroundColor(this.getGenreColor(stat.genre))
            .borderRadius(3)
        }
        .width('100%')

        // 详细信息
        Row() {
          Text(`占比 ${stat.percentage.toFixed(1)}%`)
            .fontSize(12)
            .fontColor('#999999')

          Blank()

          Text(`能量 ${Math.round(stat.averageEnergy)}`)
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F8F8F8')
    .borderRadius(8)
  }

  /**
   * 获取排名颜色
   */
  private getRankColor(index: number): string {
    switch (index) {
      case 0:
        return '#FFD700' // 金色
      case 1:
        return '#C0C0C0' // 银色
      case 2:
        return '#CD7F32' // 铜色
      default:
        return '#999999'
    }
  }

  /**
   * 获取流派颜色
   */
  private getGenreColor(genre: string): string {
    const colorMap = new Map<string, string>([
      ['流行', '#007AFF'],
      ['摇滚', '#FF3B30'],
      ['电子', '#AF52DE'],
      ['古典', '#5856D6'],
      ['爵士', '#FF9500'],
      ['嘻哈', '#34C759'],
      ['民谣', '#8E8E93'],
      ['R&B', '#FF2D55'],
      ['轻音乐', '#5AC8FA'],
      ['舞曲', '#FFCC00']
    ])

    return colorMap.get(genre) || '#007AFF'
  }
}
