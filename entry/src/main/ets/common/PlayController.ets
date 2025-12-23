import { Song } from '../model/Song'
import { PlayMode, PlayerState } from '../model/PlayState'
import { AudioPlayerService, PlayerEventListener } from '../service/AudioPlayerService'
import { PlayQueueService } from '../service/PlayQueueService'
import { GlobalPlayState, PlayStateKeys } from './GlobalPlayState'
import { PreferencesManager } from '../data/preferences/PreferencesManager'

/**
 * 播放控制器
 * 连接 AudioPlayerService、PlayQueueService 和 GlobalPlayState
 * 负责同步播放状态到 AppStorage
 */
export class PlayController implements PlayerEventListener {
  private static instance: PlayController | null = null
  private audioService: AudioPlayerService
  private queueService: PlayQueueService
  private globalState: GlobalPlayState
  private preferencesManager: PreferencesManager
  private isConnected: boolean = false
  private positionSaveTimer: number = -1

  private constructor() {
    this.audioService = AudioPlayerService.getInstance()
    this.queueService = PlayQueueService.getInstance()
    this.globalState = GlobalPlayState.getInstance()
    this.preferencesManager = PreferencesManager.getInstance()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): PlayController {
    if (!PlayController.instance) {
      PlayController.instance = new PlayController()
    }
    return PlayController.instance
  }

  /**
   * 初始化控制器
   * 连接 AudioPlayerService 的事件监听
   */
  initialize(): void {
    if (this.isConnected) {
      return
    }

    // 初始化播放队列服务
    this.queueService.initialize()

    // 注册事件监听
    this.audioService.addListener(this)
    this.isConnected = true

    // 启动定期保存位置的定时器
    this.startPositionSaveTimer()

    console.info('PlayController', 'Initialized and connected to AudioPlayerService')
  }

  /**
   * 启动定期保存播放位置的定时器
   */
  private startPositionSaveTimer(): void {
    if (this.positionSaveTimer !== -1) {
      return
    }
    // 每10秒保存一次播放位置
    this.positionSaveTimer = setInterval(() => {
      this.saveCurrentPosition()
    }, 10000)
  }

  /**
   * 停止定期保存定时器
   */
  private stopPositionSaveTimer(): void {
    if (this.positionSaveTimer !== -1) {
      clearInterval(this.positionSaveTimer)
      this.positionSaveTimer = -1
    }
  }

  /**
   * 保存当前播放位置
   */
  private async saveCurrentPosition(): Promise<void> {
    const position = this.audioService.getPlayState().currentPosition
    const currentSong = this.audioService.getCurrentSong()
    if (currentSong && position > 0) {
      await this.preferencesManager.setLastPosition(position)
      await this.preferencesManager.setLastSongId(currentSong.id)
    }
  }

  /**
   * 保存播放列表状态
   */
  async savePlaylistState(): Promise<void> {
    const queue = this.queueService.getQueue()
    if (queue.length > 0) {
      const songIds: number[] = []
      for (const song of queue) {
        songIds.push(song.id)
      }
      await this.preferencesManager.saveLastPlaylist(songIds)
    }
  }

  /**
   * 播放指定歌曲
   */
  async playSong(song: Song, index: number, playlist?: Song[]): Promise<boolean> {
    console.info('PlayController', `playSong: ${song.title} at index ${index}`)

    // 设置加载状态
    this.globalState.setIsLoading(true)

    // 如果提供了播放列表，更新队列
    if (playlist && playlist.length > 0) {
      this.queueService.setQueue(playlist, index)
    }

    // 更新全局状态
    this.globalState.setCurrentSong(song)
    this.globalState.setCurrentIndex(index)
    this.globalState.setCurrentPosition(0)

    // 添加到播放历史
    await this.preferencesManager.addPlayHistory(song.id)

    // 保存播放列表状态
    await this.savePlaylistState()

    // 调用播放服务（会自动开始播放）
    const result = await this.audioService.play(song)
    // 加载完成，清除加载状态（成功或失败都清除）
    this.globalState.setIsLoading(false)
    return result
  }

  /**
   * 播放/暂停切换
   */
  async togglePlayPause(): Promise<void> {
    const isPlaying = AppStorage.get<boolean>(PlayStateKeys.IS_PLAYING) ?? false
    console.info('PlayController', `togglePlayPause: current isPlaying=${isPlaying}`)

    if (isPlaying) {
      await this.pause()
    } else {
      await this.resume()
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    console.info('PlayController', 'pause')
    await this.audioService.pause()
    this.globalState.setIsPlaying(false)
  }

  /**
   * 继续播放
   */
  async resume(): Promise<void> {
    console.info('PlayController', 'resume')
    await this.audioService.start()
    this.globalState.setIsPlaying(true)
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    console.info('PlayController', 'stop')
    await this.audioService.stop()
    this.globalState.setIsPlaying(false)
    this.globalState.setCurrentPosition(0)
  }

  /**
   * 跳转到指定位置
   */
  async seekTo(positionMs: number): Promise<void> {
    console.info('PlayController', `seekTo: ${positionMs}ms`)
    await this.audioService.seekTo(positionMs)
    this.globalState.setCurrentPosition(positionMs)
  }

  /**
   * 播放下一首
   */
  async playNext(): Promise<void> {
    console.info('PlayController', 'playNext')
    await this.queueService.playNext()
  }

  /**
   * 播放上一首
   */
  async playPrevious(): Promise<void> {
    console.info('PlayController', 'playPrevious')
    await this.queueService.playPrevious()
  }

  /**
   * 切换播放模式
   */
  async togglePlayMode(): Promise<PlayMode> {
    const newMode = await this.queueService.togglePlayMode()
    console.info('PlayController', `togglePlayMode: ${newMode}`)
    return newMode
  }

  /**
   * 获取当前播放时间
   */
  getCurrentPosition(): number {
    return this.audioService.getPlayState().currentPosition
  }

  /**
   * 获取音频总时长
   */
  getDuration(): number {
    return this.audioService.getPlayState().duration
  }

  /**
   * 是否正在播放
   */
  isPlaying(): boolean {
    return this.audioService.getPlayState().playerState === PlayerState.PLAYING
  }

  // ========== PlayerEventListener 实现 ==========

  /**
   * 状态变化回调
   */
  onStateChanged(state: PlayerState): void {
    console.info('PlayController', `onStateChanged: ${state}`)
    const isPlaying = state === PlayerState.PLAYING
    this.globalState.setIsPlaying(isPlaying)
  }

  /**
   * 进度变化回调
   */
  onProgressChanged(position: number, duration: number): void {
    this.globalState.setCurrentPosition(position)
    // 同步更新实际播放时长（比歌曲元数据更准确）
    if (duration > 0) {
      this.globalState.setCurrentDuration(duration)
    }
  }

  /**
   * 歌曲变化回调
   */
  onSongChanged(song: Song): void {
    console.info('PlayController', `onSongChanged: ${song.title}`)
    this.globalState.setCurrentSong(song)
  }

  /**
   * 错误回调
   */
  onError(error: string): void {
    console.error('PlayController', `onError: ${error}`)
    this.globalState.setIsLoading(false)
    this.globalState.setIsPlaying(false)
  }

  /**
   * 播放完成回调
   */
  onPlayComplete(): void {
    console.info('PlayController', 'onPlayComplete')
    // AudioPlayerService 会自动处理下一首
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    if (this.isConnected) {
      // 保存当前播放位置
      await this.saveCurrentPosition()
      // 保存播放列表状态
      await this.savePlaylistState()
      // 停止定时保存
      this.stopPositionSaveTimer()
      // 移除监听器
      this.audioService.removeListener(this)
      this.isConnected = false
    }
  }
}
