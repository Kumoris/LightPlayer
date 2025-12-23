import { common } from '@kit.AbilityKit'
import { Song } from '../model/Song'
import { SongRepository } from '../data/repository/SongRepository'
import { MusicScanService, ScanProgressCallback } from '../service/MusicScanService'

/**
 * 歌曲列表ViewModel
 * 管理歌曲列表的UI状态和业务逻辑
 */
@Observed
export class SongListViewModel {
  private static instance: SongListViewModel | null = null
  private songRepository: SongRepository
  private scanService: MusicScanService
  private context: common.UIAbilityContext | null = null

  // UI状态
  songs: Song[] = []
  filteredSongs: Song[] = []
  isLoading: boolean = false
  isScanning: boolean = false
  scanProgress: number = 0
  scanTotal: number = 0
  searchKeyword: string = ''
  errorMessage: string = ''

  private constructor() {
    this.songRepository = SongRepository.getInstance()
    this.scanService = MusicScanService.getInstance()
  }

  static getInstance(): SongListViewModel {
    if (!SongListViewModel.instance) {
      SongListViewModel.instance = new SongListViewModel()
    }
    return SongListViewModel.instance
  }

  /**
   * 设置上下文
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context
  }

  /**
   * 加载所有歌曲
   */
  async loadSongs(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      this.songs = await this.songRepository.getAllSongs()
      this.filteredSongs = this.songs
    } catch (error) {
      this.errorMessage = `加载歌曲失败: ${JSON.stringify(error)}`
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 搜索歌曲
   */
  async searchSongs(keyword: string): Promise<void> {
    this.searchKeyword = keyword
    if (!keyword.trim()) {
      this.filteredSongs = this.songs
      return
    }

    try {
      this.filteredSongs = await this.songRepository.searchSongs(keyword)
    } catch (error) {
      this.errorMessage = `搜索失败: ${JSON.stringify(error)}`
    }
  }

  /**
   * 本地过滤（不查询数据库）
   */
  filterLocally(keyword: string): void {
    this.searchKeyword = keyword
    if (!keyword.trim()) {
      this.filteredSongs = this.songs
      return
    }

    const lowerKeyword = keyword.toLowerCase()
    this.filteredSongs = this.songs.filter(song =>
    song.title.toLowerCase().includes(lowerKeyword) ||
    song.artist.toLowerCase().includes(lowerKeyword) ||
    song.album.toLowerCase().includes(lowerKeyword)
    )
  }

  /**
   * 扫描音乐
   */
  async scanMusic(): Promise<void> {
    if (this.isScanning || !this.context) {
      return
    }

    this.isScanning = true
    this.scanProgress = 0
    this.scanTotal = 0
    this.errorMessage = ''

    const callback: ScanProgressCallback = {
      onProgress: (current: number, total: number, currentFile?: string): void => {
        this.scanProgress = current
        this.scanTotal = total
      },
      onComplete: (songs: Song[]): void => {
        this.songs = songs
        this.filteredSongs = songs
        this.isScanning = false
      },
      onError: (error: string): void => {
        this.errorMessage = error
        this.isScanning = false
      }
    }

    try {
      await this.scanService.scanMediaLibrary(this.context, callback)
    } catch (error) {
      this.errorMessage = `扫描失败: ${JSON.stringify(error)}`
      this.isScanning = false
    }
  }

  /**
   * 刷新歌曲库
   */
  async refreshLibrary(): Promise<void> {
    if (this.isScanning || !this.context) {
      return
    }

    this.isScanning = true
    const callback: ScanProgressCallback = {
      onProgress: (current: number, total: number, currentFile?: string): void => {
        this.scanProgress = current
        this.scanTotal = total
      },
      onComplete: (songs: Song[]): void => {
        this.songs = songs
        this.filteredSongs = songs
      }
    }

    try {
      await this.scanService.refreshLibrary(this.context, callback)
    } catch (error) {
      this.errorMessage = `刷新失败: ${JSON.stringify(error)}`
    } finally {
      this.isScanning = false
    }
  }

  /**
   * 删除歌曲
   */
  async deleteSong(songId: number): Promise<void> {
    try {
      await this.songRepository.deleteSong(songId)
      this.songs = this.songs.filter(s => s.id !== songId)
      this.filteredSongs = this.filteredSongs.filter(s => s.id !== songId)
    } catch (error) {
      this.errorMessage = `删除失败: ${JSON.stringify(error)}`
    }
  }

  /**
   * 获取歌曲数量
   */
  getSongCount(): number {
    return this.songs.length
  }

  /**
   * 获取扫描进度百分比
   */
  getScanProgressPercent(): number {
    if (this.scanTotal === 0) {
      return 0
    }
    return (this.scanProgress / this.scanTotal) * 100
  }
}
