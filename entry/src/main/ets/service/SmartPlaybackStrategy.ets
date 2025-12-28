import { Song } from '../model/Song'
import { PlayMode } from '../model/PlayState'

/**
 * 时段枚举
 */
enum TimeOfDay {
  MORNING = 'morning',     // 早晨 6:00-12:00 (高能量)
  AFTERNOON = 'afternoon', // 下午 12:00-18:00 (中等能量)
  EVENING = 'evening',     // 傍晚 18:00-22:00 (中低能量)
  NIGHT = 'night'          // 夜晚 22:00-6:00 (低能量)
}

/**
 * 播放历史记录
 */
interface PlayHistoryItem {
  songId: number
  timestamp: number
  genre: string
  album: string
}

/**
 * 能量范围接口
 */
interface EnergyRange {
  min: number
  max: number
}

/**
 * 智能播放策略服务
 * 提供智能随机、时间感知、夜间模式等高级播放策略
 */
export class SmartPlaybackStrategy {
  private static instance: SmartPlaybackStrategy | null = null

  // 播放历史记录（最近10首）
  private playHistory: PlayHistoryItem[] = []
  private readonly HISTORY_SIZE = 10

  // 智能随机配置
  private readonly SAME_GENRE_PENALTY = 0.3  // 同流派惩罚权重
  private readonly SAME_ALBUM_PENALTY = 0.2  // 同专辑惩罚权重
  private readonly MIN_REPEAT_INTERVAL = 5   // 最小重复间隔（歌曲数）

  private constructor() {}

  static getInstance(): SmartPlaybackStrategy {
    if (!SmartPlaybackStrategy.instance) {
      SmartPlaybackStrategy.instance = new SmartPlaybackStrategy()
    }
    return SmartPlaybackStrategy.instance
  }

  /**
   * 记录播放历史
   */
  recordPlay(song: Song): void {
    const historyItem: PlayHistoryItem = {
      songId: song.id,
      timestamp: Date.now(),
      genre: song.genre,
      album: song.album
    }

    this.playHistory.unshift(historyItem)

    // 保持历史记录在指定大小内
    if (this.playHistory.length > this.HISTORY_SIZE) {
      this.playHistory = this.playHistory.slice(0, this.HISTORY_SIZE)
    }
  }

  /**
   * 获取当前时段
   */
  private getCurrentTimeOfDay(): TimeOfDay {
    const hour = new Date().getHours()

    if (hour >= 6 && hour < 12) {
      return TimeOfDay.MORNING
    } else if (hour >= 12 && hour < 18) {
      return TimeOfDay.AFTERNOON
    } else if (hour >= 18 && hour < 22) {
      return TimeOfDay.EVENING
    } else {
      return TimeOfDay.NIGHT
    }
  }

  /**
   * 根据时段获取理想能量范围
   */
  private getIdealEnergyRange(timeOfDay: TimeOfDay): EnergyRange {
    switch (timeOfDay) {
      case TimeOfDay.MORNING:
        const morningRange: EnergyRange = { min: 60, max: 100 }
        return morningRange
      case TimeOfDay.AFTERNOON:
        const afternoonRange: EnergyRange = { min: 40, max: 80 }
        return afternoonRange
      case TimeOfDay.EVENING:
        const eveningRange: EnergyRange = { min: 30, max: 60 }
        return eveningRange
      case TimeOfDay.NIGHT:
        const nightRange: EnergyRange = { min: 0, max: 40 }
        return nightRange
      default:
        const defaultRange: EnergyRange = { min: 0, max: 100 }
        return defaultRange
    }
  }

  /**
   * 智能随机选择下一首歌
   * 避免同流派/专辑连续播放
   */
  selectSmartShuffleNext(playlist: Song[], currentIndex: number): number {
    if (playlist.length === 0) return -1
    if (playlist.length === 1) return 0

    // 为每首歌计算权重分数
    const weights: number[] = playlist.map((song, index) => {
      // 跳过当前歌曲
      if (index === currentIndex) return 0

      let weight = 1.0

      // 检查最近播放历史
      const recentIndex = this.playHistory.findIndex(h => h.songId === song.id)
      if (recentIndex !== -1 && recentIndex < this.MIN_REPEAT_INTERVAL) {
        // 最近播放过的歌曲降低权重
        weight *= (recentIndex + 1) / (this.MIN_REPEAT_INTERVAL + 1)
      }

      // 检查流派连续性
      if (this.playHistory.length > 0) {
        const lastGenre = this.playHistory[0].genre
        if (song.genre && song.genre === lastGenre) {
          weight *= (1 - this.SAME_GENRE_PENALTY)
        }
      }

      // 检查专辑连续性
      if (this.playHistory.length > 0) {
        const lastAlbum = this.playHistory[0].album
        if (song.album && song.album === lastAlbum) {
          weight *= (1 - this.SAME_ALBUM_PENALTY)
        }
      }

      // 避免同流派扎堆（检查最近3首）
      const recentGenres = this.playHistory.slice(0, 3).map(h => h.genre)
      const sameGenreCount = recentGenres.filter(g => g === song.genre).length
      if (sameGenreCount > 0) {
        weight *= Math.pow(0.7, sameGenreCount)
      }

      return Math.max(weight, 0.01) // 确保最小权重不为0
    })

    // 加权随机选择
    return this.weightedRandomSelect(weights)
  }

  /**
   * 时间感知选择下一首歌
   * 根据当前时段选择合适能量等级的歌曲
   */
  selectTimeAwareNext(playlist: Song[], currentIndex: number): number {
    if (playlist.length === 0) return -1
    if (playlist.length === 1) return 0

    const timeOfDay = this.getCurrentTimeOfDay()
    const idealRange = this.getIdealEnergyRange(timeOfDay)

    // 为每首歌计算权重分数
    const weights: number[] = playlist.map((song, index) => {
      // 跳过当前歌曲
      if (index === currentIndex) return 0

      let weight = 1.0

      // 根据能量等级匹配度计算权重
      const energy = song.energy || 50
      if (energy >= idealRange.min && energy <= idealRange.max) {
        // 在理想范围内，权重最高
        weight = 1.0
      } else {
        // 偏离理想范围，权重降低
        const deviation = Math.min(
          Math.abs(energy - idealRange.min),
          Math.abs(energy - idealRange.max)
        )
        weight = 1.0 / (1 + deviation / 50) // 偏离越大，权重越低
      }

      // 避免最近播放过
      const recentIndex = this.playHistory.findIndex(h => h.songId === song.id)
      if (recentIndex !== -1 && recentIndex < this.MIN_REPEAT_INTERVAL) {
        weight *= (recentIndex + 1) / (this.MIN_REPEAT_INTERVAL + 1)
      }

      return Math.max(weight, 0.01)
    })

    return this.weightedRandomSelect(weights)
  }

  /**
   * 夜间模式选择下一首歌
   * 优先选择低BPM、舒缓风格的歌曲
   */
  selectNightModeNext(playlist: Song[], currentIndex: number): number {
    if (playlist.length === 0) return -1
    if (playlist.length === 1) return 0

    // 夜间模式偏好
    const MAX_IDEAL_BPM = 100  // 理想BPM上限
    const MAX_IDEAL_ENERGY = 30 // 理想能量上限
    const calmMoods = ['平静', '放松', '舒缓', 'calm', 'relaxed', 'peaceful']

    const weights: number[] = playlist.map((song, index) => {
      // 跳过当前歌曲
      if (index === currentIndex) return 0

      let weight = 1.0

      // BPM 权重（越低越好）
      if (song.bpm > 0) {
        if (song.bpm <= MAX_IDEAL_BPM) {
          weight *= 1.5 // 低BPM加成
        } else {
          weight *= MAX_IDEAL_BPM / song.bpm // BPM越高权重越低
        }
      }

      // 能量等级权重（越低越好）
      const energy = song.energy || 50
      if (energy <= MAX_IDEAL_ENERGY) {
        weight *= 1.5 // 低能量加成
      } else {
        weight *= MAX_IDEAL_ENERGY / energy
      }

      // 情绪匹配权重
      if (song.mood && calmMoods.some(mood => song.mood.includes(mood))) {
        weight *= 1.3 // 平静情绪加成
      }

      // 避免最近播放过
      const recentIndex = this.playHistory.findIndex(h => h.songId === song.id)
      if (recentIndex !== -1 && recentIndex < this.MIN_REPEAT_INTERVAL) {
        weight *= (recentIndex + 1) / (this.MIN_REPEAT_INTERVAL + 1)
      }

      return Math.max(weight, 0.01)
    })

    return this.weightedRandomSelect(weights)
  }

  /**
   * 加权随机选择
   * @param weights 权重数组
   * @returns 选中的索引
   */
  private weightedRandomSelect(weights: number[]): number {
    const totalWeight = weights.reduce((sum, w) => sum + w, 0)

    if (totalWeight === 0) {
      // 如果所有权重都是0，随机选择
      return Math.floor(Math.random() * weights.length)
    }

    let random = Math.random() * totalWeight

    for (let i = 0; i < weights.length; i++) {
      random -= weights[i]
      if (random <= 0) {
        return i
      }
    }

    // 如果没选中（理论上不应该发生），返回最后一个非零权重的索引
    for (let i = weights.length - 1; i >= 0; i--) {
      if (weights[i] > 0) return i
    }

    return 0
  }

  /**
   * 根据播放模式选择下一首歌
   */
  selectNext(playMode: PlayMode, playlist: Song[], currentIndex: number): number {
    switch (playMode) {
      case PlayMode.SMART_SHUFFLE:
        return this.selectSmartShuffleNext(playlist, currentIndex)

      case PlayMode.TIME_AWARE:
        return this.selectTimeAwareNext(playlist, currentIndex)

      case PlayMode.NIGHT_MODE:
        return this.selectNightModeNext(playlist, currentIndex)

      default:
        // 其他模式不使用智能策略
        return -1
    }
  }

  /**
   * 获取夜间模式推荐音量
   * 随时间推移逐渐降低音量
   */
  getNightModeVolume(baseVolume: number, songDuration: number, currentPosition: number): number {
    // 在歌曲最后30%时间内逐渐降低音量
    const fadeStartPercent = 0.7
    const fadeStart = songDuration * fadeStartPercent

    if (currentPosition >= fadeStart) {
      const fadeProgress = (currentPosition - fadeStart) / (songDuration - fadeStart)
      const volumeReduction = fadeProgress * 0.3 // 最多降低30%
      return Math.max(baseVolume * (1 - volumeReduction), baseVolume * 0.5)
    }

    return baseVolume
  }

  /**
   * 清除播放历史
   */
  clearHistory(): void {
    this.playHistory = []
  }
}
