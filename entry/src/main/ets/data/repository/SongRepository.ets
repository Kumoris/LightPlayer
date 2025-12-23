import { Song } from '../../model/Song'
import { SongDao } from '../database/SongDao'

/**
 * 歌曲数据仓库
 * 作为数据层的统一入口，协调本地数据库和远程数据
 */
export class SongRepository {
  private static instance: SongRepository | null = null
  private songDao: SongDao

  private constructor() {
    this.songDao = SongDao.getInstance()
  }

  static getInstance(): SongRepository {
    if (!SongRepository.instance) {
      SongRepository.instance = new SongRepository()
    }
    return SongRepository.instance
  }

  /**
   * 获取所有歌曲
   */
  async getAllSongs(): Promise<Song[]> {
    return await this.songDao.queryAll()
  }

  /**
   * 根据ID获取歌曲
   */
  async getSongById(id: number): Promise<Song | null> {
    return await this.songDao.queryById(id)
  }

  /**
   * 根据路径获取歌曲
   */
  async getSongByPath(path: string): Promise<Song | null> {
    return await this.songDao.queryByPath(path)
  }

  /**
   * 搜索歌曲
   */
  async searchSongs(keyword: string): Promise<Song[]> {
    return await this.songDao.search(keyword)
  }

  /**
   * 保存歌曲
   */
  async saveSong(song: Song): Promise<number> {
    return await this.songDao.insert(song)
  }

  /**
   * 批量保存歌曲
   */
  async saveSongs(songs: Song[]): Promise<number> {
    return await this.songDao.insertBatch(songs)
  }

  /**
   * 删除歌曲
   */
  async deleteSong(id: number): Promise<number> {
    return await this.songDao.delete(id)
  }

  /**
   * 清空所有歌曲
   */
  async clearAllSongs(): Promise<number> {
    return await this.songDao.deleteAll()
  }
}
