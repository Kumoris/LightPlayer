/**
 * 歌曲数据模型
 */
@Observed
export class Song {
  id: number = 0
  title: string = ''
  artist: string = ''
  album: string = ''
  duration: number = 0 // 毫秒
  path: string = ''
  albumArt: string = ''
  dateAdded: number = 0
  size: number = 0
  mimeType: string = ''

  // 智能播放相关元数据
  genre: string = '' // 流派（摇滚、流行、古典等）
  bpm: number = 0 // 节奏速度（每分钟节拍数）
  energy: number = 50 // 能量等级 (0-100，0=舒缓 100=激烈)
  mood: string = '' // 情绪标签（快乐、悲伤、平静、激动等）

  /**
   * 获取格式化的时长字符串 (mm:ss)
   */
  getFormattedDuration(): string {
    const minutes = Math.floor(this.duration / 60000)
    const seconds = Math.floor((this.duration % 60000) / 1000)
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 获取格式化的文件大小
   */
  getFormattedSize(): string {
    const mb = this.size / (1024 * 1024)
    return `${mb.toFixed(2)} MB`
  }
}

/**
 * 创建Song实例的工厂函数
 */
export function createSong(
  id: number = 0,
  title: string = '',
  artist: string = '',
  album: string = '',
  duration: number = 0,
  path: string = '',
  albumArt: string = '',
  dateAdded: number = 0,
  size: number = 0,
  mimeType: string = '',
  genre: string = '',
  bpm: number = 0,
  energy: number = 50,
  mood: string = ''
): Song {
  const song = new Song()
  song.id = id
  song.title = title
  song.artist = artist
  song.album = album
  song.duration = duration
  song.path = path
  song.albumArt = albumArt
  song.dateAdded = dateAdded
  song.size = size
  song.mimeType = mimeType
  song.genre = genre
  song.bpm = bpm
  song.energy = energy
  song.mood = mood
  return song
}
