import { Song } from '../model/Song'
import { SongMetadata } from './MetadataExtractor'

/**
 * 播放行为记录接口
 */
interface PlayBehavior {
  songId: number
  genre: string
  bpm: number
  energy: number
  mood: string
  playCount: number
  skipCount: number
  completeRate: number // 完整播放比率
  lastPlayTime: number
  timeOfDay: number // 播放时的小时数
}

/**
 * 学习统计接口
 */
interface LearningStats {
  accuracyRate: number
  totalLearned: number
  genreAccuracy: Map<string, number>
  moodAccuracy: Map<string, number>
}

/**
 * 元数据学习服务
 * 基于用户播放历史优化元数据推断准确性
 */
export class MetadataLearningService {
  private static instance: MetadataLearningService | null = null

  // 播放行为记录
  private playBehaviors: Map<number, PlayBehavior> = new Map()

  // 学习权重
  private readonly PLAY_COUNT_WEIGHT = 0.3
  private readonly COMPLETE_RATE_WEIGHT = 0.5
  private readonly TIME_RELEVANCE_WEIGHT = 0.2

  // 推断调整阈值
  private readonly MIN_PLAY_COUNT = 3 // 最少播放次数才纳入学习
  private readonly HIGH_QUALITY_THRESHOLD = 0.8 // 高质量播放阈值

  private constructor() {
    this.loadFromStorage()
  }

  static getInstance(): MetadataLearningService {
    if (!MetadataLearningService.instance) {
      MetadataLearningService.instance = new MetadataLearningService()
    }
    return MetadataLearningService.instance
  }

  /**
   * 记录播放行为
   */
  recordPlayBehavior(
    song: Song,
    playDuration: number,
    isSkipped: boolean,
    timeOfDay: number
  ): void {
    const behavior = this.playBehaviors.get(song.id)

    if (behavior) {
      // 更新已有记录
      behavior.playCount++
      if (isSkipped) {
        behavior.skipCount++
      }

      // 计算完整播放率
      const completeRate = playDuration / song.duration
      behavior.completeRate =
        (behavior.completeRate * (behavior.playCount - 1) + completeRate) / behavior.playCount

      behavior.lastPlayTime = Date.now()
      behavior.timeOfDay = timeOfDay
    } else {
      // 创建新记录
      const newBehavior: PlayBehavior = {
        songId: song.id,
        genre: song.genre,
        bpm: song.bpm,
        energy: song.energy,
        mood: song.mood,
        playCount: 1,
        skipCount: isSkipped ? 1 : 0,
        completeRate: playDuration / song.duration,
        lastPlayTime: Date.now(),
        timeOfDay: timeOfDay
      }
      this.playBehaviors.set(song.id, newBehavior)
    }

    this.saveToStorage()
  }

  /**
   * 学习并优化元数据
   * 基于播放行为调整元数据推断
   */
  optimizeMetadata(song: Song, inferredMetadata: SongMetadata): SongMetadata {
    const behavior = this.playBehaviors.get(song.id)

    // 如果没有足够的播放数据，返回原始推断
    if (!behavior || behavior.playCount < this.MIN_PLAY_COUNT) {
      return inferredMetadata
    }

    // 计算播放质量分数
    const qualityScore = this.calculateQualityScore(behavior)

    // 如果播放质量低，可能推断有误，需要调整
    if (qualityScore < this.HIGH_QUALITY_THRESHOLD) {
      return this.adjustMetadata(inferredMetadata, behavior)
    }

    return inferredMetadata
  }

  /**
   * 计算播放质量分数
   */
  private calculateQualityScore(behavior: PlayBehavior): number {
    // 跳过率（越低越好）
    const skipRate = behavior.skipCount / behavior.playCount
    const skipScore = 1 - skipRate

    // 完整播放率（越高越好）
    const completeScore = behavior.completeRate

    // 播放频率（播放次数多表明喜欢）
    const frequencyScore = Math.min(behavior.playCount / 10, 1.0)

    return (
      skipScore * this.PLAY_COUNT_WEIGHT +
      completeScore * this.COMPLETE_RATE_WEIGHT +
      frequencyScore * this.TIME_RELEVANCE_WEIGHT
    )
  }

  /**
   * 调整元数据
   */
  private adjustMetadata(
    original: SongMetadata,
    behavior: PlayBehavior
  ): SongMetadata {
    const adjusted: SongMetadata = {
      genre: original.genre,
      bpm: original.bpm,
      energy: original.energy,
      mood: original.mood
    }

    // 如果跳过率高，降低能量等级
    const skipRate = behavior.skipCount / behavior.playCount
    if (skipRate > 0.5) {
      adjusted.energy = Math.max(0, original.energy - 15)
    }

    // 如果完整播放率高，说明能量匹配较好
    if (behavior.completeRate > 0.9) {
      // 保持当前能量等级
      adjusted.energy = original.energy
    }

    // 根据播放时段调整
    const hour = behavior.timeOfDay
    if (hour >= 22 || hour < 6) {
      // 夜间播放，降低能量和BPM
      adjusted.energy = Math.max(0, Math.min(40, adjusted.energy))
      adjusted.bpm = Math.max(60, Math.min(100, adjusted.bpm))
    }

    return adjusted
  }

  /**
   * 获取学习统计
   */
  getLearningStats(): LearningStats {
    let totalLearned = 0
    const genreAccuracy = new Map<string, number>()
    const moodAccuracy = new Map<string, number>()

    const behaviorIterator = this.playBehaviors.values()
    let behaviorEntry = behaviorIterator.next()

    while (!behaviorEntry.done) {
      const behavior = behaviorEntry.value
      if (behavior.playCount >= this.MIN_PLAY_COUNT) {
        totalLearned++

        const score = this.calculateQualityScore(behavior)

        // 统计流派准确性
        const genreScore = genreAccuracy.get(behavior.genre)
        if (genreScore !== undefined) {
          genreAccuracy.set(behavior.genre, (genreScore + score) / 2)
        } else {
          genreAccuracy.set(behavior.genre, score)
        }

        // 统计情绪准确性
        const moodScore = moodAccuracy.get(behavior.mood)
        if (moodScore !== undefined) {
          moodAccuracy.set(behavior.mood, (moodScore + score) / 2)
        } else {
          moodAccuracy.set(behavior.mood, score)
        }
      }

      behaviorEntry = behaviorIterator.next()
    }

    // 计算总体准确率
    let totalScore = 0
    const genreIterator = genreAccuracy.values()
    let genreEntry = genreIterator.next()
    while (!genreEntry.done) {
      totalScore += genreEntry.value
      genreEntry = genreIterator.next()
    }

    const accuracyRate = totalLearned > 0 ? totalScore / totalLearned : 0

    const stats: LearningStats = {
      accuracyRate: accuracyRate,
      totalLearned: totalLearned,
      genreAccuracy: genreAccuracy,
      moodAccuracy: moodAccuracy
    }

    return stats
  }

  /**
   * 推荐相似歌曲
   * 基于已学习的用户偏好
   */
  recommendSimilarSongs(currentSong: Song, allSongs: Song[]): Song[] {
    const currentBehavior = this.playBehaviors.get(currentSong.id)

    // 如果当前歌曲没有行为数据，返回同流派的歌曲
    if (!currentBehavior) {
      const similarGenre: Song[] = []
      for (let i = 0; i < allSongs.length; i++) {
        const song = allSongs[i]
        if (song.genre === currentSong.genre && song.id !== currentSong.id) {
          similarGenre.push(song)
        }
      }
      return similarGenre.slice(0, 10)
    }

    // 计算每首歌的相似度分数
    const scoredSongs: Array<{ song: Song; score: number }> = []

    for (let i = 0; i < allSongs.length; i++) {
      const song = allSongs[i]
      if (song.id === currentSong.id) {
        continue
      }

      let score = 0

      // 流派匹配 (30%)
      if (song.genre === currentSong.genre) {
        score += 0.3
      }

      // BPM相似度 (20%)
      const bpmDiff = Math.abs(song.bpm - currentSong.bpm)
      score += (1 - Math.min(bpmDiff / 60, 1)) * 0.2

      // 能量相似度 (30%)
      const energyDiff = Math.abs(song.energy - currentSong.energy)
      score += (1 - energyDiff / 100) * 0.3

      // 情绪匹配 (20%)
      if (song.mood === currentSong.mood) {
        score += 0.2
      }

      scoredSongs.push({ song: song, score: score })
    }

    // 排序并返回前10首
    scoredSongs.sort((a, b) => b.score - a.score)

    const recommendations: Song[] = []
    for (let i = 0; i < Math.min(10, scoredSongs.length); i++) {
      recommendations.push(scoredSongs[i].song)
    }

    return recommendations
  }

  /**
   * 保存到本地存储
   */
  private saveToStorage(): void {
    // TODO: 实现本地存储持久化
    console.info('MetadataLearningService', `Saved ${this.playBehaviors.size} behaviors`)
  }

  /**
   * 从本地存储加载
   */
  private loadFromStorage(): void {
    // TODO: 实现从本地存储加载
    console.info('MetadataLearningService', 'Loaded play behaviors from storage')
  }

  /**
   * 清除学习数据
   */
  clearLearningData(): void {
    this.playBehaviors.clear()
    this.saveToStorage()
  }
}
