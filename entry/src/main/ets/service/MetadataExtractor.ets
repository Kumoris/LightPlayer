/**
 * BPM范围接口
 */
interface BPMRange {
  min: number
  max: number
  avg: number
}

/**
 * 能量范围接口
 */
interface EnergyRange {
  min: number
  max: number
}

/**
 * 歌曲元数据接口
 */
export interface SongMetadata {
  genre: string
  bpm: number
  energy: number
  mood: string
}

/**
 * 歌曲信息输入接口
 */
export interface SongInfo {
  title: string
  artist: string
  album: string
  filePath: string
}

/**
 * 音乐元数据提取器
 * 使用启发式算法推断歌曲的流派、BPM、能量等级和情绪
 * 由于 HarmonyOS 缺少音频分析库，使用基于规则的智能推断
 */
export class MetadataExtractor {
  private static instance: MetadataExtractor | null = null

  // 流派关键词映射
  private readonly GENRE_KEYWORDS = new Map<string, string[]>([
    ['摇滚', ['rock', 'metal', 'punk', '摇滚', '金属']],
    ['流行', ['pop', 'mainstream', '流行', 'jpop', 'kpop', 'cpop']],
    ['电子', ['electronic', 'edm', 'techno', 'house', 'dubstep', '电子', 'electro']],
    ['古典', ['classical', 'symphony', 'orchestra', '古典', '交响']],
    ['爵士', ['jazz', 'blues', '爵士', '蓝调']],
    ['嘻哈', ['hiphop', 'hip-hop', 'rap', 'trap', '嘻哈', '说唱']],
    ['民谣', ['folk', 'acoustic', 'country', '民谣', '乡村']],
    ['R&B', ['r&b', 'rnb', 'soul', 'funk']],
    ['轻音乐', ['easy listening', 'lounge', 'ambient', 'chill', '轻音乐', '氛围']],
    ['舞曲', ['dance', 'disco', 'club', '舞曲']]
  ])

  // 流派对应的典型 BPM 范围
  private readonly GENRE_BPM_MAP = new Map<string, BPMRange>([
    ['摇滚', { min: 110, max: 140, avg: 125 } as BPMRange],
    ['流行', { min: 100, max: 130, avg: 115 } as BPMRange],
    ['电子', { min: 120, max: 150, avg: 135 } as BPMRange],
    ['古典', { min: 60, max: 120, avg: 90 } as BPMRange],
    ['爵士', { min: 80, max: 140, avg: 110 } as BPMRange],
    ['嘻哈', { min: 70, max: 110, avg: 90 } as BPMRange],
    ['民谣', { min: 70, max: 100, avg: 85 } as BPMRange],
    ['R&B', { min: 70, max: 110, avg: 90 } as BPMRange],
    ['轻音乐', { min: 60, max: 90, avg: 75 } as BPMRange],
    ['舞曲', { min: 120, max: 140, avg: 130 } as BPMRange]
  ])

  // 流派对应的典型能量等级
  private readonly GENRE_ENERGY_MAP = new Map<string, number>([
    ['摇滚', 80],
    ['流行', 65],
    ['电子', 85],
    ['古典', 35],
    ['爵士', 55],
    ['嘻哈', 70],
    ['民谣', 40],
    ['R&B', 60],
    ['轻音乐', 25],
    ['舞曲', 90]
  ])

  // 流派对应的典型情绪
  private readonly GENRE_MOOD_MAP = new Map<string, string[]>([
    ['摇滚', ['激情', '力量', '反叛']],
    ['流行', ['快乐', '轻松', '浪漫']],
    ['电子', ['激动', '节奏', '未来']],
    ['古典', ['优雅', '平静', '深沉']],
    ['爵士', ['慵懒', '优雅', '复古']],
    ['嘻哈', ['自信', '节奏', '态度']],
    ['民谣', ['温暖', '怀旧', '平静']],
    ['R&B', ['浪漫', '感性', '舒缓']],
    ['轻音乐', ['放松', '平静', '舒缓']],
    ['舞曲', ['兴奋', '活力', '派对']]
  ])

  // 情绪关键词（用于从文件名/标题推断）
  private readonly MOOD_KEYWORDS = new Map<string, string[]>([
    ['快乐', ['happy', 'joy', 'cheerful', 'upbeat', '快乐', '欢乐', '愉快']],
    ['悲伤', ['sad', 'melancholy', 'sorrow', '悲伤', '忧郁', '伤感']],
    ['平静', ['calm', 'peaceful', 'serene', 'tranquil', '平静', '安静', '宁静']],
    ['激动', ['excited', 'energetic', 'intense', '激动', '激情', '热情']],
    ['浪漫', ['romantic', 'love', 'tender', '浪漫', '爱', '温柔']],
    ['放松', ['relax', 'chill', 'easy', '放松', '轻松', '休闲']]
  ])

  private constructor() {}

  static getInstance(): MetadataExtractor {
    if (!MetadataExtractor.instance) {
      MetadataExtractor.instance = new MetadataExtractor()
    }
    return MetadataExtractor.instance
  }

  /**
   * 推断歌曲流派
   * 基于文件路径、艺术家名、标题中的关键词
   */
  inferGenre(title: string, artist: string, album: string, filePath: string): string {
    const searchText = `${title} ${artist} ${album} ${filePath}`.toLowerCase()

    // 遍历流派关键词，查找匹配
    const genreIterator = this.GENRE_KEYWORDS.entries()
    let genreEntry = genreIterator.next()
    while (!genreEntry.done) {
      const genre = genreEntry.value[0]
      const keywords = genreEntry.value[1]
      for (let i = 0; i < keywords.length; i++) {
        const keyword = keywords[i]
        if (searchText.includes(keyword.toLowerCase())) {
          return genre
        }
      }
      genreEntry = genreIterator.next()
    }

    // 如果没有匹配，返回默认流派
    return '流行' // 默认流派
  }

  /**
   * 根据流派推断 BPM
   * 在典型范围内随机选择，增加多样性
   */
  inferBPM(genre: string): number {
    const bpmRange = this.GENRE_BPM_MAP.get(genre)

    if (bpmRange) {
      // 在范围内随机选择，偏向平均值
      const variance = (bpmRange.max - bpmRange.min) * 0.3
      const randomBPM = bpmRange.avg + (Math.random() - 0.5) * variance
      return Math.round(randomBPM)
    }

    // 默认 BPM (流行音乐标准)
    return 120
  }

  /**
   * 根据流派推断能量等级
   * 结合文件名中的关键词进行微调
   */
  inferEnergy(genre: string, title: string): number {
    let baseEnergy = this.GENRE_ENERGY_MAP.get(genre) || 50

    // 根据标题关键词微调能量
    const titleLower = title.toLowerCase()

    // 高能量关键词
    if (titleLower.includes('remix') || titleLower.includes('dance') ||
        titleLower.includes('party') || titleLower.includes('激情') ||
        titleLower.includes('rock')) {
      baseEnergy = Math.min(100, baseEnergy + 15)
    }

    // 低能量关键词
    if (titleLower.includes('ballad') || titleLower.includes('acoustic') ||
        titleLower.includes('slow') || titleLower.includes('piano') ||
        titleLower.includes('慢') || titleLower.includes('轻')) {
      baseEnergy = Math.max(0, baseEnergy - 20)
    }

    // 添加一些随机变化 (±10)
    baseEnergy += (Math.random() - 0.5) * 20

    return Math.max(0, Math.min(100, Math.round(baseEnergy)))
  }

  /**
   * 推断歌曲情绪
   * 基于流派和标题关键词
   */
  inferMood(genre: string, title: string): string {
    const titleLower = title.toLowerCase()

    // 首先尝试从标题中直接匹配情绪关键词
    const moodIterator = this.MOOD_KEYWORDS.entries()
    let moodEntry = moodIterator.next()
    while (!moodEntry.done) {
      const mood = moodEntry.value[0]
      const keywords = moodEntry.value[1]
      for (let i = 0; i < keywords.length; i++) {
        const keyword = keywords[i]
        if (titleLower.includes(keyword.toLowerCase())) {
          return mood
        }
      }
      moodEntry = moodIterator.next()
    }

    // 如果没有匹配，从流派获取默认情绪
    const moods = this.GENRE_MOOD_MAP.get(genre)
    if (moods && moods.length > 0) {
      // 随机选择流派的一个典型情绪
      return moods[Math.floor(Math.random() * moods.length)]
    }

    // 默认情绪
    return '轻松'
  }

  /**
   * 提取完整的歌曲元数据
   * @param title 歌曲标题
   * @param artist 艺术家
   * @param album 专辑
   * @param filePath 文件路径
   * @returns 包含 genre, bpm, energy, mood 的对象
   */
  extractMetadata(
    title: string,
    artist: string,
    album: string,
    filePath: string
  ): SongMetadata {
    const genre = this.inferGenre(title, artist, album, filePath)
    const bpm = this.inferBPM(genre)
    const energy = this.inferEnergy(genre, title)
    const mood = this.inferMood(genre, title)

    console.info('MetadataExtractor',
      `Extracted metadata for "${title}": genre=${genre}, bpm=${bpm}, energy=${energy}, mood=${mood}`)

    const metadata: SongMetadata = {
      genre: genre,
      bpm: bpm,
      energy: energy,
      mood: mood
    }
    return metadata
  }

  /**
   * 批量提取元数据
   * @param songs 歌曲信息数组
   * @returns 包含元数据的数组
   */
  batchExtractMetadata(songs: SongInfo[]): SongMetadata[] {
    const results: SongMetadata[] = []
    for (let i = 0; i < songs.length; i++) {
      const song = songs[i]
      const metadata = this.extractMetadata(
        song.title,
        song.artist,
        song.album,
        song.filePath
      )
      results.push(metadata)
    }
    return results
  }

  /**
   * 根据时间段推荐合适的能量范围（用于智能播放）
   */
  getRecommendedEnergyForTime(hour: number): EnergyRange {
    if (hour >= 6 && hour < 12) {
      const range: EnergyRange = { min: 60, max: 100 }
      return range
    } else if (hour >= 12 && hour < 18) {
      const range: EnergyRange = { min: 40, max: 80 }
      return range
    } else if (hour >= 18 && hour < 22) {
      const range: EnergyRange = { min: 30, max: 60 }
      return range
    } else {
      const range: EnergyRange = { min: 0, max: 40 }
      return range
    }
  }

  /**
   * 验证并修正元数据值
   */
  validateMetadata(metadata: SongMetadata | null): SongMetadata {
    if (!metadata) {
      const defaultMetadata: SongMetadata = {
        genre: '流行',
        bpm: 120,
        energy: 50,
        mood: '轻松'
      }
      return defaultMetadata
    }

    const validatedMetadata: SongMetadata = {
      genre: metadata.genre || '流行',
      bpm: metadata.bpm && metadata.bpm > 0 ? Math.min(200, metadata.bpm) : 120,
      energy: metadata.energy !== undefined ? Math.max(0, Math.min(100, metadata.energy)) : 50,
      mood: metadata.mood || '轻松'
    }
    return validatedMetadata
  }
}
