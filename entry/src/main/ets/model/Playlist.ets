/**
 * 播放列表数据模型
 */
@Observed
export class Playlist {
  id: number = 0
  name: string = ''
  description: string = ''
  coverUri: string = ''
  songIds: number[] = []
  createTime: number = 0
  updateTime: number = 0

  /**
   * 获取歌曲数量
   */
  getSongCount(): number {
    return this.songIds.length
  }
}

/**
 * 创建Playlist实例的工厂函数
 */
export function createPlaylist(
  id: number = 0,
  name: string = '',
  description: string = '',
  coverUri: string = '',
  songIds: number[] = [],
  createTime: number = 0,
  updateTime: number = 0
): Playlist {
  const playlist = new Playlist()
  playlist.id = id
  playlist.name = name
  playlist.description = description
  playlist.coverUri = coverUri
  playlist.songIds = songIds
  playlist.createTime = createTime
  playlist.updateTime = updateTime
  return playlist
}
