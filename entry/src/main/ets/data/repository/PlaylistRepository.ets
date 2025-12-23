import { Playlist } from '../../model/Playlist'
import { PlaylistDao } from '../database/PlaylistDao'

/**
 * 播放列表数据仓库
 */
export class PlaylistRepository {
  private static instance: PlaylistRepository | null = null
  private playlistDao: PlaylistDao

  private constructor() {
    this.playlistDao = PlaylistDao.getInstance()
  }

  static getInstance(): PlaylistRepository {
    if (!PlaylistRepository.instance) {
      PlaylistRepository.instance = new PlaylistRepository()
    }
    return PlaylistRepository.instance
  }

  /**
   * 获取所有播放列表
   */
  async getAllPlaylists(): Promise<Playlist[]> {
    return await this.playlistDao.queryAll()
  }

  /**
   * 根据ID获取播放列表
   */
  async getPlaylistById(id: number): Promise<Playlist | null> {
    return await this.playlistDao.queryById(id)
  }

  /**
   * 创建播放列表
   */
  async createPlaylist(playlist: Playlist): Promise<number> {
    return await this.playlistDao.create(playlist)
  }

  /**
   * 更新播放列表
   */
  async updatePlaylist(playlist: Playlist): Promise<number> {
    return await this.playlistDao.update(playlist)
  }

  /**
   * 删除播放列表
   */
  async deletePlaylist(id: number): Promise<number> {
    return await this.playlistDao.delete(id)
  }

  /**
   * 添加歌曲到播放列表
   */
  async addSongToPlaylist(playlistId: number, songId: number): Promise<number> {
    return await this.playlistDao.addSong(playlistId, songId)
  }

  /**
   * 从播放列表移除歌曲
   */
  async removeSongFromPlaylist(playlistId: number, songId: number): Promise<number> {
    return await this.playlistDao.removeSong(playlistId, songId)
  }
}
