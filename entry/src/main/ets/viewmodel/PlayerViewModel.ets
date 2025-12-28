import { Song } from '../model/Song'
import { PlayState, PlayMode, PlayerState } from '../model/PlayState'
import { AudioPlayerService, PlayerEventListener } from '../service/AudioPlayerService'
import { PromptService } from '../service/PromptService'

/**
 * 播放器ViewModel
 * 连接UI层和Service层，管理播放相关的UI状态
 */
@Observed
export class PlayerViewModel {
  private static instance: PlayerViewModel | null = null
  private playerService: AudioPlayerService
  private promptService: PromptService

  // UI状态
  currentSong: Song | null = null
  isPlaying: boolean = false
  currentPosition: number = 0
  duration: number = 0
  playMode: PlayMode = PlayMode.SEQUENCE
  playlist: Song[] = []
  isLoading: boolean = false
  errorMessage: string = ''

  private constructor() {
    this.playerService = AudioPlayerService.getInstance()
    this.promptService = PromptService.getInstance()
    this.setupListener()
  }

  static getInstance(): PlayerViewModel {
    if (!PlayerViewModel.instance) {
      PlayerViewModel.instance = new PlayerViewModel()
    }
    return PlayerViewModel.instance
  }

  /**
   * 设置播放器监听
   */
  private setupListener(): void {
    const listener: PlayerEventListener = {
      onStateChanged: (state: PlayerState) => {
        this.isPlaying = state === PlayerState.PLAYING
        this.isLoading = state === PlayerState.IDLE
      },
      onProgressChanged: (position: number, duration: number) => {
        this.currentPosition = position
        this.duration = duration
      },
      onSongChanged: (song: Song) => {
        this.currentSong = song
        this.duration = song.duration
      },
      onError: (error: string) => {
        this.errorMessage = error
        this.isLoading = false
      },
      onPlayComplete: () => {
        // 播放完成后的处理
      }
    }
    this.playerService.addListener(listener)
  }

  /**
   * 初始化
   */
  async initialize(): Promise<void> {
    try {
      await this.playerService.initialize()
      this.playMode = this.playerService.getPlayState().playMode
    } catch (error) {
      this.errorMessage = `初始化播放器失败: ${JSON.stringify(error)}`
    }
  }

  /**
   * 播放歌曲
   */
  async playSong(song: Song): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      await this.playerService.play(song)
      await this.playerService.start()
    } catch (error) {
      this.errorMessage = `播放失败: ${JSON.stringify(error)}`
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 播放列表中的歌曲
   */
  async playFromList(songs: Song[], index: number): Promise<void> {
    this.playlist = songs
    this.playerService.setPlaylist(songs, index)
    await this.playerService.playAtIndex(index)
    await this.playerService.start()
  }

  /**
   * 播放/暂停切换
   */
  async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      await this.playerService.pause()
    } else {
      await this.playerService.start()
    }
  }

  /**
   * 播放下一首
   */
  async playNext(): Promise<void> {
    await this.playerService.playNext()
  }

  /**
   * 播放上一首
   */
  async playPrevious(): Promise<void> {
    await this.playerService.playPrevious()
  }

  /**
   * 跳转到指定位置
   */
  async seekTo(position: number): Promise<void> {
    await this.playerService.seekTo(position)
  }

  /**
   * 切换播放模式
   */
  async togglePlayMode(): Promise<void> {
    this.playMode = await this.playerService.togglePlayMode()
    // 显示模式切换提示
    this.promptService.showPlayModeToast(this.playMode)
  }

  /**
   * 设置播放模式（直接设置，不循环）
   */
  async setPlayMode(mode: PlayMode): Promise<void> {
    await this.playerService.setPlayMode(mode)
    this.playMode = mode
    // 显示模式切换提示
    this.promptService.showPlayModeToast(this.playMode)
  }

  /**
   * 获取进度百分比
   */
  getProgressPercent(): number {
    if (this.duration === 0) {
      return 0
    }
    return (this.currentPosition / this.duration) * 100
  }

  /**
   * 获取格式化的当前时间
   */
  getFormattedCurrentTime(): string {
    return this.formatTime(this.currentPosition)
  }

  /**
   * 获取格式化的总时长
   */
  getFormattedDuration(): string {
    return this.formatTime(this.duration)
  }

  /**
   * 格式化时间
   */
  private formatTime(ms: number): string {
    const minutes = Math.floor(ms / 60000)
    const seconds = Math.floor((ms % 60000) / 1000)
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 获取播放模式图标名称
   */
  getPlayModeIconName(): string {
    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        return 'sequence'
      case PlayMode.LOOP:
        return 'loop'
      case PlayMode.SINGLE:
        return 'single'
      case PlayMode.SMART_SHUFFLE:
        return 'smart_shuffle'
      case PlayMode.TIME_AWARE:
        return 'time_aware'
      case PlayMode.NIGHT_MODE:
        return 'night_mode'
      default:
        return 'sequence'
    }
  }

  /**
   * 获取播放模式显示名称
   */
  getPlayModeName(): string {
    switch (this.playMode) {
      case PlayMode.SEQUENCE:
        return '顺序播放'
      case PlayMode.LOOP:
        return '列表循环'
      case PlayMode.SINGLE:
        return '单曲循环'
      case PlayMode.SMART_SHUFFLE:
        return '智能随机'
      case PlayMode.TIME_AWARE:
        return '时间感知'
      case PlayMode.NIGHT_MODE:
        return '夜间模式'
      default:
        return '顺序播放'
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    await this.playerService.release()
  }
}
