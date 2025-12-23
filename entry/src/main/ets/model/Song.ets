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
  mimeType: string = ''
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
  return song
}
