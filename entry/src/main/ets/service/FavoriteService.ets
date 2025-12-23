import { Song } from '../model/Song'
import { SongRepository } from '../data/repository/SongRepository'

/**
 * 收藏服务
 * 管理歌曲收藏功能
 * 使用 AppStorage 实现全局状态共享
 */
export class FavoriteService {
  private static instance: FavoriteService | null = null
  private songRepository: SongRepository

  // 收藏的歌曲 ID 集合
  private favoriteIds: Set<number> = new Set()

  // 状态变化监听器
  private listeners: Array<(favoriteIds: Set<number>) => void> = []

  private constructor() {
    this.songRepository = SongRepository.getInstance()
    this.loadFavorites()
  }

  static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService()
    }
    return FavoriteService.instance
  }

  /**
   * 从本地存储加载收藏列表
   */
  private loadFavorites(): void {
    try {
      const stored = AppStorage.get<string>('favorite_song_ids')
      if (stored) {
        const ids: number[] = JSON.parse(stored)
        this.favoriteIds = new Set(ids)
        console.info('FavoriteService', `Loaded ${this.favoriteIds.size} favorites`)
      }
    } catch (error) {
      console.error('FavoriteService', `Load favorites failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 保存收藏列表到本地存储
   */
  private saveFavorites(): void {
    try {
      const ids = Array.from(this.favoriteIds)
      AppStorage.setOrCreate<string>('favorite_song_ids', JSON.stringify(ids))
      console.info('FavoriteService', `Saved ${this.favoriteIds.size} favorites`)
    } catch (error) {
      console.error('FavoriteService', `Save favorites failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 检查歌曲是否已收藏
   */
  isFavorite(songId: number): boolean {
    return this.favoriteIds.has(songId)
  }

  /**
   * 添加收藏
   */
  addFavorite(songId: number): void {
    if (!this.favoriteIds.has(songId)) {
      this.favoriteIds.add(songId)
      this.saveFavorites()
      this.notifyListeners()
      console.info('FavoriteService', `Added favorite: ${songId}`)
    }
  }

  /**
   * 移除收藏
   */
  removeFavorite(songId: number): void {
    if (this.favoriteIds.has(songId)) {
      this.favoriteIds.delete(songId)
      this.saveFavorites()
      this.notifyListeners()
      console.info('FavoriteService', `Removed favorite: ${songId}`)
    }
  }

  /**
   * 切换收藏状态
   */
  toggleFavorite(songId: number): boolean {
    if (this.favoriteIds.has(songId)) {
      this.removeFavorite(songId)
      return false
    } else {
      this.addFavorite(songId)
      return true
    }
  }

  /**
   * 获取所有收藏的歌曲 ID
   */
  getFavoriteIds(): number[] {
    return Array.from(this.favoriteIds)
  }

  /**
   * 获取收藏数量
   */
  getFavoriteCount(): number {
    return this.favoriteIds.size
  }

  /**
   * 获取所有收藏的歌曲
   */
  async getFavoriteSongs(): Promise<Song[]> {
    const songs: Song[] = []
    for (const songId of this.favoriteIds) {
      const song = await this.songRepository.getSongById(songId)
      if (song) {
        songs.push(song)
      }
    }
    return songs
  }

  /**
   * 添加监听器
   */
  addListener(listener: (favoriteIds: Set<number>) => void): void {
    this.listeners.push(listener)
  }

  /**
   * 移除监听器
   */
  removeListener(listener: (favoriteIds: Set<number>) => void): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(): void {
    for (const listener of this.listeners) {
      listener(new Set(this.favoriteIds))
    }
  }

  /**
   * 清空所有收藏
   */
  clearFavorites(): void {
    this.favoriteIds.clear()
    this.saveFavorites()
    this.notifyListeners()
    console.info('FavoriteService', 'Cleared all favorites')
  }
}
