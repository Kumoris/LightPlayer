import { Playlist } from '../model/Playlist'
import { Song } from '../model/Song'
import { PlaylistService } from '../service/PlaylistService'

/**
 * 播放列表ViewModel
 */
@Observed
export class PlaylistViewModel {
  private static instance: PlaylistViewModel | null = null
  private playlistService: PlaylistService

  // UI状态
  playlists: Playlist[] = []
  currentPlaylist: Playlist | null = null
  currentPlaylistSongs: Song[] = []
  isLoading: boolean = false
  errorMessage: string = ''

  private constructor() {
    this.playlistService = PlaylistService.getInstance()
  }

  static getInstance(): PlaylistViewModel {
    if (!PlaylistViewModel.instance) {
      PlaylistViewModel.instance = new PlaylistViewModel()
    }
    return PlaylistViewModel.instance
  }

  /**
   * 加载所有播放列表
   */
  async loadPlaylists(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      this.playlists = await this.playlistService.getAllPlaylists()
    } catch (error) {
      this.errorMessage = `加载播放列表失败: ${JSON.stringify(error)}`
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 加载播放列表详情
   */
  async loadPlaylistDetail(playlistId: number): Promise<void> {
    this.isLoading = true
    try {
      const result = await this.playlistService.getPlaylistWithSongs(playlistId)
      if (result) {
        this.currentPlaylist = result.playlist
        this.currentPlaylistSongs = result.songs
      }
    } catch (error) {
      this.errorMessage = `加载播放列表详情失败: ${JSON.stringify(error)}`
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 创建播放列表
   */
  async createPlaylist(name: string, description: string = ''): Promise<number> {
    try {
      const id = await this.playlistService.createPlaylist(name, description)
      await this.loadPlaylists() // 刷新列表
      return id
    } catch (error) {
      this.errorMessage = `创建播放列表失败: ${JSON.stringify(error)}`
      return -1
    }
  }

  /**
   * 删除播放列表
   */
  async deletePlaylist(playlistId: number): Promise<void> {
    try {
      await this.playlistService.deletePlaylist(playlistId)
      this.playlists = this.playlists.filter(p => p.id !== playlistId)
    } catch (error) {
      this.errorMessage = `删除播放列表失败: ${JSON.stringify(error)}`
    }
  }

  /**
   * 添加歌曲到播放列表
   */
  async addSongToPlaylist(playlistId: number, songId: number): Promise<boolean> {
    try {
      const result = await this.playlistService.addSongToPlaylist(playlistId, songId)
      if (result > 0) {
        // 如果当前正在查看该播放列表，刷新详情
        if (this.currentPlaylist?.id === playlistId) {
          await this.loadPlaylistDetail(playlistId)
        }
        return true
      }
      return false
    } catch (error) {
      this.errorMessage = `添加歌曲失败: ${JSON.stringify(error)}`
      return false
    }
  }

  /**
   * 从播放列表移除歌曲
   */
  async removeSongFromPlaylist(playlistId: number, songId: number): Promise<void> {
    try {
      await this.playlistService.removeSongFromPlaylist(playlistId, songId)
      if (this.currentPlaylist?.id === playlistId) {
        this.currentPlaylistSongs = this.currentPlaylistSongs.filter(s => s.id !== songId)
      }
    } catch (error) {
      this.errorMessage = `移除歌曲失败: ${JSON.stringify(error)}`
    }
  }
}
