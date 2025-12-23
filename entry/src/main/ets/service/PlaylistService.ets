import { Playlist, createPlaylist } from '../model/Playlist'
import { Song } from '../model/Song'
import { PlaylistRepository } from '../data/repository/PlaylistRepository'
import { SongRepository } from '../data/repository/SongRepository'

/**
 * 播放列表和歌曲组合结果
 */
interface PlaylistWithSongs {
  playlist: Playlist
  songs: Song[]
}

/**
 * 播放列表服务
 * 管理播放列表的业务逻辑
 */
export class PlaylistService {
  private static instance: PlaylistService | null = null
  private playlistRepository: PlaylistRepository
  private songRepository: SongRepository

  private constructor() {
    this.playlistRepository = PlaylistRepository.getInstance()
    this.songRepository = SongRepository.getInstance()
  }

  static getInstance(): PlaylistService {
    if (!PlaylistService.instance) {
      PlaylistService.instance = new PlaylistService()
    }
    return PlaylistService.instance
  }

  /**
   * 获取所有播放列表
   */
  async getAllPlaylists(): Promise<Playlist[]> {
    return await this.playlistRepository.getAllPlaylists()
  }

  /**
   * 获取播放列表详情（包含歌曲）
   */
  async getPlaylistWithSongs(playlistId: number): Promise<PlaylistWithSongs | null> {
    const playlist = await this.playlistRepository.getPlaylistById(playlistId)
    if (!playlist) {
      return null
    }

    const songs: Song[] = []
    for (const songId of playlist.songIds) {
      const song = await this.songRepository.getSongById(songId)
      if (song) {
        songs.push(song)
      }
    }

    const result: PlaylistWithSongs = {
      playlist: playlist,
      songs: songs
    }
    return result
  }

  /**
   * 创建播放列表
   */
  async createPlaylist(name: string, description: string = ''): Promise<number> {
    const playlist = createPlaylist(0, name, description, '', [], Date.now(), Date.now())
    return await this.playlistRepository.createPlaylist(playlist)
  }

  /**
   * 更新播放列表信息
   */
  async updatePlaylist(playlist: Playlist): Promise<number> {
    return await this.playlistRepository.updatePlaylist(playlist)
  }

  /**
   * 删除播放列表
   */
  async deletePlaylist(playlistId: number): Promise<number> {
    return await this.playlistRepository.deletePlaylist(playlistId)
  }

  /**
   * 添加歌曲到播放列表
   */
  async addSongToPlaylist(playlistId: number, songId: number): Promise<number> {
    // 检查歌曲是否已在播放列表中
    const playlist = await this.playlistRepository.getPlaylistById(playlistId)
    if (playlist && playlist.songIds.includes(songId)) {
      return 0 // 歌曲已存在
    }
    return await this.playlistRepository.addSongToPlaylist(playlistId, songId)
  }

  /**
   * 批量添加歌曲到播放列表
   */
  async addSongsToPlaylist(playlistId: number, songIds: number[]): Promise<number> {
    let addedCount = 0
    for (const songId of songIds) {
      const result = await this.addSongToPlaylist(playlistId, songId)
      if (result > 0) {
        addedCount++
      }
    }
    return addedCount
  }

  /**
   * 从播放列表移除歌曲
   */
  async removeSongFromPlaylist(playlistId: number, songId: number): Promise<number> {
    return await this.playlistRepository.removeSongFromPlaylist(playlistId, songId)
  }

  /**
   * 获取最近播放列表（基于更新时间）
   */
  async getRecentPlaylists(limit: number = 5): Promise<Playlist[]> {
    const allPlaylists = await this.getAllPlaylists()
    return allPlaylists.slice(0, limit)
  }
}
