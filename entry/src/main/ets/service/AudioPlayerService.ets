import { media } from '@kit.MediaKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { Song } from '../model/Song'
import { PlayState, PlayerState, PlayMode } from '../model/PlayState'
import { PreferencesManager } from '../data/preferences/PreferencesManager'
import { BackgroundTaskManager } from './BackgroundTaskManager'
import { MediaSessionManager, MediaSessionEventListener } from './MediaSessionManager'
import { AudioFocusManager, AudioFocusChange, AudioFocusListener } from './AudioFocusManager'
import { SmartPlaybackStrategy } from './SmartPlaybackStrategy'

/**
 * 播放器事件监听器接口
 */
export interface PlayerEventListener {
  onStateChanged?: (state: PlayerState) => void
  onProgressChanged?: (position: number, duration: number) => void
  onSongChanged?: (song: Song) => void
  onError?: (error: string) => void
  onPlayComplete?: () => void
}

/**
 * 音频播放服务
 * 封装AVPlayer，提供播放控制功能
 * 集成后台任务、媒体会话和音频焦点管理
 */
export class AudioPlayerService {
  private static instance: AudioPlayerService | null = null
  private avPlayer: media.AVPlayer | null = null
  private currentSong: Song | null = null
  private playState: PlayState = new PlayState()
  private playlist: Song[] = []
  private currentIndex: number = -1
  private listeners: PlayerEventListener[] = []
  private progressTimer: number = -1
  private preferencesManager: PreferencesManager
  private initialized: boolean = false

  // 后台播放相关
  private backgroundTaskManager: BackgroundTaskManager
  private mediaSessionManager: MediaSessionManager
  private audioFocusManager: AudioFocusManager
  private context: Context | null = null
  private wasPlayingBeforeInterrupt: boolean = false

  // 智能播放策略
  private smartPlaybackStrategy: SmartPlaybackStrategy

  // 用于等待 prepared 状态
  private prepareResolve: (() => void) | null = null
  private shouldAutoPlay: boolean = false

  // 当前打开的文件描述符
  private currentFd: number = -1

  private constructor() {
    this.preferencesManager = PreferencesManager.getInstance()
    this.backgroundTaskManager = BackgroundTaskManager.getInstance()
    this.mediaSessionManager = MediaSessionManager.getInstance()
    this.audioFocusManager = AudioFocusManager.getInstance()
    this.smartPlaybackStrategy = SmartPlaybackStrategy.getInstance()
  }

  static getInstance(): AudioPlayerService {
    if (!AudioPlayerService.instance) {
      AudioPlayerService.instance = new AudioPlayerService()
    }
    return AudioPlayerService.instance
  }

  /**
   * 初始化播放器
   * @param context 应用上下文（用于后台任务和媒体会话）
   */
  async initialize(context?: Context): Promise<boolean> {
    try {
      if (context) {
        this.context = context
      }

      this.avPlayer = await media.createAVPlayer()
      this.setupPlayerCallbacks()

      // 恢复上次的播放模式
      this.playState.playMode = await this.preferencesManager.getPlayMode()

      // 初始化后台任务管理器
      if (this.context) {
        this.backgroundTaskManager.initialize(this.context)

        // 初始化媒体会话
        await this.mediaSessionManager.initialize(this.context)
        this.setupMediaSessionCallbacks()

        // 初始化音频焦点管理
        await this.audioFocusManager.initialize()
        this.setupAudioFocusCallbacks()
      }

      this.initialized = true
      return true
    } catch (error) {
      console.error('AudioPlayerService', `Initialize player failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 设置媒体会话回调
   */
  private setupMediaSessionCallbacks(): void {
    const sessionListener: MediaSessionEventListener = {
      onPlay: () => {
        this.start()
      },
      onPause: () => {
        this.pause()
      },
      onPlayNext: () => {
        this.playNext()
      },
      onPlayPrevious: () => {
        this.playPrevious()
      },
      onSeek: (time: number) => {
        this.seekTo(time)
      }
    }
    this.mediaSessionManager.setEventListener(sessionListener)
  }

  /**
   * 设置音频焦点回调
   */
  private setupAudioFocusCallbacks(): void {
    const focusListener: AudioFocusListener = {
      onFocusChange: (change: AudioFocusChange) => {
        this.handleAudioFocusChange(change)
      }
    }
    this.audioFocusManager.setFocusListener(focusListener)
  }

  /**
   * 处理音频焦点变化
   */
  private handleAudioFocusChange(change: AudioFocusChange): void {
    console.info('AudioPlayerService', `Audio focus changed: ${change}`)

    switch (change) {
      case AudioFocusChange.LOSS_TRANSIENT:
        // 短暂失去焦点（如来电），暂停播放
        if (this.playState.playerState === PlayerState.PLAYING) {
          this.wasPlayingBeforeInterrupt = true
          this.pause()
        }
        break

      case AudioFocusChange.LOSS:
        // 永久失去焦点，停止播放
        this.wasPlayingBeforeInterrupt = false
        this.stop()
        break

      case AudioFocusChange.GAIN:
        // 重新获得焦点，恢复播放
        if (this.wasPlayingBeforeInterrupt) {
          this.wasPlayingBeforeInterrupt = false
          this.start()
        }
        break

      case AudioFocusChange.LOSS_TRANSIENT_CAN_DUCK:
        // 可降低音量继续播放（当前实现暂不处理音量调节）
        break
    }
  }

  /**
   * 是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized
  }

  /**
   * 设置播放器回调
   */
  private setupPlayerCallbacks(): void {
    if (!this.avPlayer) {
      return
    }

    this.avPlayer.on('stateChange', (state: string) => {
      this.handleStateChange(state)
    })

    this.avPlayer.on('error', (error: BusinessError) => {
      console.error('AudioPlayerService', `Player error: ${JSON.stringify(error)}`)
      this.playState.playerState = PlayerState.ERROR
      this.notifyStateChanged(PlayerState.ERROR)
      this.notifyError(`播放错误: ${error.message}`)
    })

    this.avPlayer.on('durationUpdate', (duration: number) => {
      console.info('AudioPlayerService', `Duration updated: ${duration}ms`)
      this.playState.duration = duration
      // 立即通知监听器 duration 变化
      this.notifyProgressChanged(this.playState.currentPosition, duration)
    })

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.playState.currentPosition = time
    })
  }

  /**
   * 处理播放器状态变化
   */
  private handleStateChange(state: string): void {
    console.info('AudioPlayerService', `State changed to: ${state}`)

    switch (state) {
      case 'idle':
        this.playState.playerState = PlayerState.IDLE
        break
      case 'initialized':
        if (this.avPlayer) {
          try {
            this.avPlayer.prepare()
          } catch (e) {
            console.error('AudioPlayerService', `Failed to prepare: ${e}`)
          }
        }
        break
      case 'prepared':
        this.playState.playerState = PlayerState.PREPARED
        if (this.avPlayer) {
          this.playState.duration = this.avPlayer.duration
          console.info('AudioPlayerService', `Prepared with duration: ${this.playState.duration}ms`)
          // 立即通知 duration，确保 UI 能显示
          this.notifyProgressChanged(0, this.playState.duration)
        }
        this.notifyStateChanged(PlayerState.PREPARED)

        // 解决 prepare 等待
        if (this.prepareResolve) {
          this.prepareResolve()
          this.prepareResolve = null
        }

        // 如果需要自动播放，则开始播放
        if (this.shouldAutoPlay) {
          this.shouldAutoPlay = false
          try {
            this.avPlayer?.play()
          } catch (e) {
            console.error('AudioPlayerService', `Failed to auto play: ${e}`)
          }
        }
        break
      case 'playing':
        this.playState.playerState = PlayerState.PLAYING
        this.startProgressTimer()
        this.notifyStateChanged(PlayerState.PLAYING)
        // 更新媒体会话播放状态
        this.updateMediaSessionPlaybackState(true)
        // 记录播放历史（用于智能播放策略）
        if (this.currentSong) {
          this.smartPlaybackStrategy.recordPlay(this.currentSong)
        }
        break
      case 'paused':
        this.playState.playerState = PlayerState.PAUSED
        this.stopProgressTimer()
        this.notifyStateChanged(PlayerState.PAUSED)
        // 更新媒体会话播放状态
        this.updateMediaSessionPlaybackState(false)
        break
      case 'completed':
        this.stopProgressTimer()
        this.notifyPlayComplete()
        this.handlePlayComplete()
        break
      case 'stopped':
        this.playState.playerState = PlayerState.STOPPED
        this.stopProgressTimer()
        this.notifyStateChanged(PlayerState.STOPPED)
        // 更新媒体会话播放状态
        this.updateMediaSessionPlaybackState(false)
        break
      case 'error':
        this.playState.playerState = PlayerState.ERROR
        this.notifyStateChanged(PlayerState.ERROR)
        break
    }
  }

  /**
   * 更新媒体会话播放状态
   */
  private updateMediaSessionPlaybackState(isPlaying: boolean): void {
    this.mediaSessionManager.updatePlaybackState(
      isPlaying,
      this.playState.currentPosition,
      this.playState.duration
    )
  }

  /**
   * 关闭当前打开的文件描述符
   */
  private closeCurrentFd(): void {
    if (this.currentFd !== -1) {
      try {
        fileIo.closeSync(this.currentFd)
        console.info('AudioPlayerService', `Closed file fd: ${this.currentFd}`)
      } catch (error) {
        console.warn('AudioPlayerService', `Failed to close fd: ${JSON.stringify(error)}`)
      }
      this.currentFd = -1
    }
  }

  /**
   * 播放指定歌曲
   */
  async play(song: Song): Promise<boolean> {
    if (!this.avPlayer) {
      console.error('AudioPlayerService', 'AVPlayer not initialized')
      return false
    }

    try {
      console.info('AudioPlayerService', `Playing song: ${song.title}, path: ${song.path}`)

      // 重置播放器
      await this.avPlayer.reset()

      // 关闭之前打开的文件描述符
      this.closeCurrentFd()

      // 设置自动播放标志
      this.shouldAutoPlay = true

      // 打开文件获取文件描述符
      const file = fileIo.openSync(song.path, fileIo.OpenMode.READ_ONLY)
      this.currentFd = file.fd
      console.info('AudioPlayerService', `Opened file with fd: ${this.currentFd}`)

      // 获取文件大小
      const stat = fileIo.statSync(this.currentFd)
      const fileLength = stat.size
      console.info('AudioPlayerService', `File size: ${fileLength}`)

      // 使用 fdSrc 设置音频源（用于本地文件）
      this.avPlayer.fdSrc = {
        fd: this.currentFd,
        offset: 0,
        length: fileLength
      }

      this.currentSong = song
      this.playState.currentSongId = song.id

      // 保存当前播放的歌曲
      await this.preferencesManager.setLastSongId(song.id)

      // 启动后台任务（确保后台播放）
      await this.backgroundTaskManager.startBackgroundRunning()

      // 激活并更新媒体会话
      await this.mediaSessionManager.activate()
      await this.mediaSessionManager.updateMetadata(song)

      // 设置音频焦点
      this.audioFocusManager.setPlaying(true)

      this.notifySongChanged(song)
      return true
    } catch (error) {
      console.error('AudioPlayerService', `Play song failed: ${JSON.stringify(error)}`)
      this.shouldAutoPlay = false
      return false
    }
  }

  /**
   * 播放播放列表中的歌曲
   */
  async playAtIndex(index: number): Promise<boolean> {
    if (index < 0 || index >= this.playlist.length) {
      return false
    }
    this.currentIndex = index
    // play() 方法会设置 shouldAutoPlay = true
    return await this.play(this.playlist[index])
  }

  /**
   * 开始播放（从prepared状态）
   */
  async start(): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    if (this.playState.playerState === PlayerState.PREPARED ||
        this.playState.playerState === PlayerState.PAUSED) {
      try {
        await this.avPlayer.play()
      } catch (error) {
        console.error('AudioPlayerService', `Start play failed: ${JSON.stringify(error)}`)
      }
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    if (this.playState.playerState === PlayerState.PLAYING) {
      try {
        await this.avPlayer.pause()
        // 保存当前位置
        await this.preferencesManager.setLastPosition(this.playState.currentPosition)
      } catch (error) {
        console.error('AudioPlayerService', `Pause failed: ${JSON.stringify(error)}`)
      }
    }
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    try {
      await this.avPlayer.stop()

      // 放弃音频焦点
      this.audioFocusManager.abandonFocus()

      // 停止后台任务
      await this.backgroundTaskManager.stopBackgroundRunning()

      // 停用媒体会话
      await this.mediaSessionManager.deactivate()
    } catch (error) {
      console.error('AudioPlayerService', `Stop failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 跳转到指定位置
   */
  async seekTo(position: number): Promise<void> {
    if (!this.avPlayer) {
      return
    }
    if (this.playState.playerState === PlayerState.PLAYING ||
        this.playState.playerState === PlayerState.PAUSED) {
      try {
        await this.avPlayer.seek(position)
      } catch (error) {
        console.error('AudioPlayerService', `Seek failed: ${JSON.stringify(error)}`)
      }
    }
  }

  /**
   * 播放下一首
   */
  async playNext(): Promise<void> {
    if (this.playlist.length === 0) {
      return
    }

    let nextIndex = this.currentIndex

    // 使用智能播放策略
    if (this.playState.playMode === PlayMode.SMART_SHUFFLE ||
        this.playState.playMode === PlayMode.TIME_AWARE ||
        this.playState.playMode === PlayMode.NIGHT_MODE) {
      // 使用智能策略选择下一首
      nextIndex = this.smartPlaybackStrategy.selectNext(
        this.playState.playMode,
        this.playlist,
        this.currentIndex
      )

      // 如果智能策略返回 -1（不应该发生），回退到顺序播放
      if (nextIndex === -1 || nextIndex === this.currentIndex) {
        nextIndex = this.currentIndex + 1
        if (nextIndex >= this.playlist.length) {
          nextIndex = 0
        }
      }
    } else {
      // 顺序播放模式
      nextIndex = this.currentIndex + 1
      if (nextIndex >= this.playlist.length) {
        nextIndex = 0
      }
    }

    // playAtIndex 会自动开始播放
    await this.playAtIndex(nextIndex)
  }

  /**
   * 播放上一首
   */
  async playPrevious(): Promise<void> {
    if (this.playlist.length === 0) {
      return
    }

    let prevIndex = this.currentIndex - 1
    if (prevIndex < 0) {
      prevIndex = this.playlist.length - 1
    }

    // playAtIndex 会自动开始播放
    await this.playAtIndex(prevIndex)
  }

  /**
   * 处理播放完成
   */
  private async handlePlayComplete(): Promise<void> {
    switch (this.playState.playMode) {
      case PlayMode.SINGLE:
        // 单曲循环 - play() 会自动开始播放
        if (this.currentSong) {
          await this.play(this.currentSong)
        }
        break
      case PlayMode.SEQUENCE:
        // 顺序播放
        if (this.currentIndex < this.playlist.length - 1) {
          await this.playNext()
        }
        break
      case PlayMode.LOOP:
      case PlayMode.SMART_SHUFFLE:
      case PlayMode.TIME_AWARE:
      case PlayMode.NIGHT_MODE:
        // 列表循环、智能模式 - 继续播放下一首
        await this.playNext()
        break
    }
  }

  /**
   * 设置播放模式
   */
  async setPlayMode(mode: PlayMode): Promise<void> {
    this.playState.playMode = mode
    await this.preferencesManager.setPlayMode(mode)
  }

  /**
   * 切换播放模式
   */
  async togglePlayMode(): Promise<PlayMode> {
    const modes: PlayMode[] = [
      PlayMode.SEQUENCE,      // 顺序播放
      PlayMode.LOOP,          // 列表循环
      PlayMode.SINGLE,        // 单曲循环
      PlayMode.SMART_SHUFFLE, // 智能随机
      PlayMode.TIME_AWARE,    // 时间感知
      PlayMode.NIGHT_MODE     // 夜间模式
    ]
    const currentModeIndex = modes.indexOf(this.playState.playMode)
    const nextMode = modes[(currentModeIndex + 1) % modes.length]
    await this.setPlayMode(nextMode)
    return nextMode
  }

  /**
   * 设置播放列表
   */
  setPlaylist(songs: Song[], startIndex: number = 0): void {
    this.playlist = songs
    this.currentIndex = startIndex
  }

  /**
   * 获取当前播放列表
   */
  getPlaylist(): Song[] {
    return this.playlist
  }

  /**
   * 获取当前歌曲
   */
  getCurrentSong(): Song | null {
    return this.currentSong
  }

  /**
   * 获取播放状态
   */
  getPlayState(): PlayState {
    return this.playState
  }

  /**
   * 添加事件监听器
   */
  addListener(listener: PlayerEventListener): void {
    this.listeners.push(listener)
  }

  /**
   * 移除事件监听器
   */
  removeListener(listener: PlayerEventListener): void {
    const index = this.listeners.indexOf(listener)
    if (index !== -1) {
      this.listeners.splice(index, 1)
    }
  }

  /**
   * 开始进度计时器
   * 使用 500ms 间隔确保进度条更新更平滑
   */
  private startProgressTimer(): void {
    this.stopProgressTimer()
    this.progressTimer = setInterval(() => {
      if (this.avPlayer) {
        const position = this.avPlayer.currentTime || 0
        const duration = this.avPlayer.duration || 0
        // 确保值有效
        if (!isNaN(position) && !isNaN(duration)) {
          // 更新本地状态
          this.playState.currentPosition = position
          if (duration > 0) {
            this.playState.duration = duration
          }
          // 通知监听器（即使 duration 为 0 也通知位置）
          this.notifyProgressChanged(position, this.playState.duration)
        }
      }
    }, 500) // 500ms 更新一次，更平滑
  }

  /**
   * 停止进度计时器
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer)
      this.progressTimer = -1
    }
  }

  /**
   * 通知状态变化
   */
  private notifyStateChanged(state: PlayerState): void {
    for (const listener of this.listeners) {
      if (listener.onStateChanged) {
        listener.onStateChanged(state)
      }
    }
  }

  /**
   * 通知进度变化
   */
  private notifyProgressChanged(position: number, duration: number): void {
    for (const listener of this.listeners) {
      if (listener.onProgressChanged) {
        listener.onProgressChanged(position, duration)
      }
    }
  }

  /**
   * 通知歌曲变化
   */
  private notifySongChanged(song: Song): void {
    for (const listener of this.listeners) {
      if (listener.onSongChanged) {
        listener.onSongChanged(song)
      }
    }
  }

  /**
   * 通知错误
   */
  private notifyError(error: string): void {
    for (const listener of this.listeners) {
      if (listener.onError) {
        listener.onError(error)
      }
    }
  }

  /**
   * 通知播放完成
   */
  private notifyPlayComplete(): void {
    for (const listener of this.listeners) {
      if (listener.onPlayComplete) {
        listener.onPlayComplete()
      }
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    this.stopProgressTimer()

    // 关闭文件描述符
    this.closeCurrentFd()

    // 释放后台相关资源
    await this.audioFocusManager.release()
    await this.mediaSessionManager.release()
    await this.backgroundTaskManager.release()

    if (this.avPlayer) {
      try {
        await this.avPlayer.release()
      } catch (error) {
        console.error('AudioPlayerService', `Release failed: ${JSON.stringify(error)}`)
      }
      this.avPlayer = null
    }
    this.listeners = []
    this.initialized = false
    this.context = null
  }
}
