import { Song } from '../model/Song'

/**
 * 流派统计数据接口
 */
export interface GenreStatistic {
  genre: string
  count: number
  percentage: number
  totalDuration: number
  averageEnergy: number
}

/**
 * 音乐统计服务
 * 提供音乐库的各种统计分析
 */
export class MusicStatisticsService {
  private static instance: MusicStatisticsService | null = null

  private constructor() {}

  static getInstance(): MusicStatisticsService {
    if (!MusicStatisticsService.instance) {
      MusicStatisticsService.instance = new MusicStatisticsService()
    }
    return MusicStatisticsService.instance
  }

  /**
   * 计算流派统计
   */
  calculateGenreStatistics(songs: Song[]): GenreStatistic[] {
    if (songs.length === 0) {
      return []
    }

    // 按流派分组
    const genreMap = new Map<string, Song[]>()

    for (let i = 0; i < songs.length; i++) {
      const song = songs[i]
      const genre = song.genre || '未知'

      const existingSongs = genreMap.get(genre)
      if (existingSongs) {
        existingSongs.push(song)
      } else {
        const newArray: Song[] = [song]
        genreMap.set(genre, newArray)
      }
    }

    // 计算统计数据
    const statistics: GenreStatistic[] = []
    const totalCount = songs.length

    const genreIterator = genreMap.entries()
    let genreEntry = genreIterator.next()

    while (!genreEntry.done) {
      const genre = genreEntry.value[0]
      const genreSongs = genreEntry.value[1]
      const count = genreSongs.length

      // 计算总时长
      let totalDuration = 0
      let totalEnergy = 0

      for (let i = 0; i < genreSongs.length; i++) {
        const song = genreSongs[i]
        totalDuration += song.duration
        totalEnergy += song.energy || 50
      }

      const statistic: GenreStatistic = {
        genre: genre,
        count: count,
        percentage: (count / totalCount) * 100,
        totalDuration: totalDuration,
        averageEnergy: totalEnergy / count
      }

      statistics.push(statistic)
      genreEntry = genreIterator.next()
    }

    // 按数量排序
    statistics.sort((a, b) => b.count - a.count)

    return statistics
  }

  /**
   * 获取最常播放的流派
   */
  getMostPlayedGenre(songs: Song[]): string {
    const stats = this.calculateGenreStatistics(songs)
    if (stats.length > 0) {
      return stats[0].genre
    }
    return '未知'
  }

  /**
   * 获取平均能量等级
   */
  getAverageEnergy(songs: Song[]): number {
    if (songs.length === 0) {
      return 50
    }

    let totalEnergy = 0
    for (let i = 0; i < songs.length; i++) {
      totalEnergy += songs[i].energy || 50
    }

    return Math.round(totalEnergy / songs.length)
  }

  /**
   * 获取平均BPM
   */
  getAverageBPM(songs: Song[]): number {
    if (songs.length === 0) {
      return 120
    }

    let totalBPM = 0
    let validCount = 0

    for (let i = 0; i < songs.length; i++) {
      const bpm = songs[i].bpm
      if (bpm && bpm > 0) {
        totalBPM += bpm
        validCount++
      }
    }

    if (validCount === 0) {
      return 120
    }

    return Math.round(totalBPM / validCount)
  }

  /**
   * 格式化时长（毫秒转小时分钟）
   */
  formatDuration(ms: number): string {
    const hours = Math.floor(ms / 3600000)
    const minutes = Math.floor((ms % 3600000) / 60000)

    if (hours > 0) {
      return `${hours}小时${minutes}分钟`
    }
    return `${minutes}分钟`
  }
}
