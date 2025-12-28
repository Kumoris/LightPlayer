import { Song } from '../model/Song'
import { PlayMode } from '../model/PlayState'
import { AudioPlayerService } from './AudioPlayerService'
import { GlobalPlayState, PlayStateKeys } from '../common/GlobalPlayState'

/**
 * 播放队列变化监听器
 */
export interface PlayQueueChangeListener {
  onQueueChanged?: (queue: Song[]) => void
  onCurrentIndexChanged?: (index: number) => void
  onPlayModeChanged?: (mode: PlayMode) => void
  onSongRemoved?: (song: Song, index: number) => void
  onQueueCleared?: () => void
}

/**
 * 播放队列服务
 * 负责管理当前播放队列、播放顺序和播放模式
 */
export class PlayQueueService {
  private static instance: PlayQueueService | null = null
  private audioService: AudioPlayerService
  private globalState: GlobalPlayState
  private queue: Song[] = []
  private currentIndex: number = -1
  private playMode: PlayMode = PlayMode.SEQUENCE
  private shuffleOrder: number[] = [] // 随机播放顺序
  private shuffleIndex: number = -1 // 在随机顺序中的位置
  private listeners: PlayQueueChangeListener[] = []
  private playHistory: number[] = [] // 播放历史（用于随机模式的上一曲）

  private constructor() {
    this.audioService = AudioPlayerService.getInstance()
    this.globalState = GlobalPlayState.getInstance()
  }

  static getInstance(): PlayQueueService {
    if (!PlayQueueService.instance) {
      PlayQueueService.instance = new PlayQueueService()
    }
    return PlayQueueService.instance
  }

  /**
   * 初始化服务
   */
  initialize(): void {
    // 从 GlobalState 同步播放模式
    const storedMode = AppStorage.get<number>(PlayStateKeys.PLAY_MODE)
    if (storedMode !== undefined) {
      this.playMode = storedMode
    }
    console.info('PlayQueueService', 'Initialized')
  }

  /**
   * 设置播放队列
   */
  setQueue(songs: Song[], startIndex: number = 0): void {
    this.queue = [...songs]
    this.currentIndex = startIndex

    // 同步到 AudioPlayerService
    this.audioService.setPlaylist(songs, startIndex)

    // 同步到 GlobalState
    this.globalState.setSongList(songs)
    this.globalState.setCurrentIndex(startIndex)

    // 清空播放历史
    this.playHistory = []

    // 通知监听器
    this.notifyQueueChanged()
    this.notifyCurrentIndexChanged()

    console.info('PlayQueueService', `Queue set with ${songs.length} songs, starting at index ${startIndex}`)
  }

  /**
   * 添加歌曲到队列末尾
   */
  addToQueue(song: Song): void {
    this.queue.push(song)

    // 同步
    this.audioService.setPlaylist(this.queue, this.currentIndex)
    this.globalState.setSongList(this.queue)

    this.notifyQueueChanged()
    console.info('PlayQueueService', `Song added to queue: ${song.title}`)
  }

  /**
   * 添加歌曲到下一首播放
   */
  addToNext(song: Song): void {
    const insertIndex = this.currentIndex + 1
    this.queue.splice(insertIndex, 0, song)

    // 同步
    this.audioService.setPlaylist(this.queue, this.currentIndex)
    this.globalState.setSongList(this.queue)

    this.notifyQueueChanged()
    console.info('PlayQueueService', `Song added to play next: ${song.title}`)
  }

  /**
   * 从队列移除歌曲
   */
  removeFromQueue(index: number): Song | null {
    if (index < 0 || index >= this.queue.length) {
      return null
    }

    const removedSong = this.queue[index]
    this.queue.splice(index, 1)

    // 更新当前索引
    if (index < this.currentIndex) {
      this.currentIndex--
    } else if (index === this.currentIndex) {
      // 如果删除的是当前歌曲
      if (this.currentIndex >= this.queue.length) {
        this.currentIndex = this.queue.length - 1
      }
    }

    // 同步
    this.audioService.setPlaylist(this.queue, this.currentIndex)
    this.globalState.setSongList(this.queue)
    this.globalState.setCurrentIndex(this.currentIndex)

    // 通知监听器
    this.notifyQueueChanged()
    this.notifyCurrentIndexChanged()
    this.notifySongRemoved(removedSong, index)

    console.info('PlayQueueService', `Song removed from queue: ${removedSong.title}`)
    return removedSong
  }

  /**
   * 清空队列
   */
  clearQueue(): void {
    this.queue = []
    this.currentIndex = -1
    this.shuffleOrder = []
    this.shuffleIndex = -1
    this.playHistory = []

    // 同步
    this.audioService.setPlaylist([], 0)
    this.globalState.setSongList([])
    this.globalState.setCurrentIndex(-1)

    // 通知监听器
    this.notifyQueueChanged()
    this.notifyCurrentIndexChanged()
    this.notifyQueueCleared()

    console.info('PlayQueueService', 'Queue cleared')
  }

  /**
   * 获取队列
   */
  getQueue(): Song[] {
    return [...this.queue]
  }

  /**
   * 获取队列长度
   */
  getQueueLength(): number {
    return this.queue.length
  }

  /**
   * 获取当前索引
   */
  getCurrentIndex(): number {
    return this.currentIndex
  }

  /**
   * 设置当前索引（不播放）
   */
  setCurrentIndex(index: number): void {
    if (index >= 0 && index < this.queue.length) {
      this.currentIndex = index
      this.globalState.setCurrentIndex(index)
      this.notifyCurrentIndexChanged()
    }
  }

  /**
   * 获取当前歌曲
   */
  getCurrentSong(): Song | null {
    if (this.currentIndex >= 0 && this.currentIndex < this.queue.length) {
      return this.queue[this.currentIndex]
    }
    return null
  }

  /**
   * 播放指定索引的歌曲
   */
  async playAtIndex(index: number): Promise<boolean> {
    if (index < 0 || index >= this.queue.length) {
      return false
    }

    // 记录播放历史（用于随机模式的上一曲）
    if (this.currentIndex >= 0) {
      this.playHistory.push(this.currentIndex)
      // 限制历史记录长度
      if (this.playHistory.length > 50) {
        this.playHistory.shift()
      }
    }

    this.currentIndex = index

    // 同步到 GlobalState
    this.globalState.setCurrentIndex(index)
    this.globalState.setCurrentSong(this.queue[index])

    // 调用 AudioPlayerService 播放（会自动开始）
    const result = await this.audioService.playAtIndex(index)

    this.notifyCurrentIndexChanged()
    return result
  }

  /**
   * 播放下一首
   */
  async playNext(): Promise<boolean> {
    if (this.queue.length === 0) {
      return false
    }

    const nextIndex = this.getNextIndex()
    if (nextIndex === -1) {
      // 顺序播放到末尾，停止
      console.info('PlayQueueService', 'Reached end of queue in sequence mode')
      return false
    }

    return await this.playAtIndex(nextIndex)
  }

  /**
   * 播放上一首
   */
  async playPrevious(): Promise<boolean> {
    if (this.queue.length === 0) {
      return false
    }

    const prevIndex = this.getPreviousIndex()
    return await this.playAtIndex(prevIndex)
  }

  /**
   * 获取下一首的索引
   */
  getNextIndex(): number {
    if (this.queue.length === 0) {
      return -1
    }

    switch (this.playMode) {
      case PlayMode.SINGLE:
        // 单曲循环，返回当前索引
        return this.currentIndex

      case PlayMode.LOOP:
        // 列表循环
        return (this.currentIndex + 1) % this.queue.length

      case PlayMode.SEQUENCE:
      default:
        // 顺序播放
        if (this.currentIndex < this.queue.length - 1) {
          return this.currentIndex + 1
        }
        return -1 // 到达末尾
    }
  }

  /**
   * 获取上一首的索引
   */
  getPreviousIndex(): number {
    if (this.queue.length === 0) {
      return -1
    }

    switch (this.playMode) {
      case PlayMode.SINGLE:
        // 单曲循环，返回当前索引
        return this.currentIndex

      case PlayMode.LOOP:
      case PlayMode.SEQUENCE:
      default:
        // 循环或顺序播放
        if (this.currentIndex > 0) {
          return this.currentIndex - 1
        }
        return this.queue.length - 1
    }
  }

  /**
   * 获取随机模式下的下一首索引
   */
  private getNextShuffleIndex(): number {
    if (this.shuffleOrder.length === 0) {
      this.generateShuffleOrder()
    }

    this.shuffleIndex++
    if (this.shuffleIndex >= this.shuffleOrder.length) {
      // 重新洗牌
      this.generateShuffleOrder()
      this.shuffleIndex = 0
    }

    return this.shuffleOrder[this.shuffleIndex]
  }

  /**
   * 生成随机播放顺序
   */
  private generateShuffleOrder(): void {
    this.shuffleOrder = []
    for (let i = 0; i < this.queue.length; i++) {
      this.shuffleOrder.push(i)
    }

    // Fisher-Yates 洗牌算法
    for (let i = this.shuffleOrder.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const temp = this.shuffleOrder[i]
      this.shuffleOrder[i] = this.shuffleOrder[j]
      this.shuffleOrder[j] = temp
    }

    // 如果当前歌曲在随机列表中，将其移到开头
    if (this.currentIndex >= 0) {
      const currentPos = this.shuffleOrder.indexOf(this.currentIndex)
      if (currentPos > 0) {
        this.shuffleOrder.splice(currentPos, 1)
        this.shuffleOrder.unshift(this.currentIndex)
      }
    }

    this.shuffleIndex = 0
    console.info('PlayQueueService', 'Shuffle order generated')
  }

  /**
   * 设置播放模式
   */
  async setPlayMode(mode: PlayMode): Promise<void> {
    this.playMode = mode

    // 同步到 AudioPlayerService 和 GlobalState
    await this.audioService.setPlayMode(mode)
    this.globalState.setPlayMode(mode)

    this.notifyPlayModeChanged()
    console.info('PlayQueueService', `Play mode changed to: ${this.getPlayModeName(mode)}`)
  }

  /**
   * 切换播放模式
   */
  async togglePlayMode(): Promise<PlayMode> {
    const modes: PlayMode[] = [PlayMode.SEQUENCE, PlayMode.LOOP, PlayMode.SINGLE, PlayMode.SMART_SHUFFLE, PlayMode.TIME_AWARE, PlayMode.NIGHT_MODE]
    const currentModeIndex = modes.indexOf(this.playMode)
    const nextMode = modes[(currentModeIndex + 1) % modes.length]
    await this.setPlayMode(nextMode)
    return nextMode
  }

  /**
   * 获取当前播放模式
   */
  getPlayMode(): PlayMode {
    return this.playMode
  }

  /**
   * 获取播放模式名称
   */
  getPlayModeName(mode?: PlayMode): string {
    const m = mode ?? this.playMode
    switch (m) {
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
        return '未知'
    }
  }

  /**
   * 获取播放模式图标名称
   */
  getPlayModeIcon(mode?: PlayMode): string {
    const m = mode ?? this.playMode
    switch (m) {
      case PlayMode.SEQUENCE:
        return 'ic_mode_sequence'
      case PlayMode.LOOP:
        return 'ic_mode_loop'
      case PlayMode.SINGLE:
        return 'ic_mode_single'
      case PlayMode.SMART_SHUFFLE:
        return 'ic_mode_shuffle'
      case PlayMode.TIME_AWARE:
        return 'ic_mode_sequence'
      case PlayMode.NIGHT_MODE:
        return 'ic_mode_single'
      default:
        return 'ic_mode_sequence'
    }
  }

  /**
   * 将歌曲移动到指定位置
   */
  moveSong(fromIndex: number, toIndex: number): boolean {
    if (fromIndex < 0 || fromIndex >= this.queue.length ||
        toIndex < 0 || toIndex >= this.queue.length) {
      return false
    }

    const song = this.queue.splice(fromIndex, 1)[0]
    this.queue.splice(toIndex, 0, song)

    // 更新当前索引
    if (this.currentIndex === fromIndex) {
      this.currentIndex = toIndex
    } else if (fromIndex < this.currentIndex && toIndex >= this.currentIndex) {
      this.currentIndex--
    } else if (fromIndex > this.currentIndex && toIndex <= this.currentIndex) {
      this.currentIndex++
    }

    // 同步
    this.audioService.setPlaylist(this.queue, this.currentIndex)
    this.globalState.setSongList(this.queue)
    this.globalState.setCurrentIndex(this.currentIndex)

    this.notifyQueueChanged()
    this.notifyCurrentIndexChanged()

    return true
  }

  /**
   * 检查歌曲是否在队列中
   */
  isInQueue(songId: number): boolean {
    return this.queue.some(song => song.id === songId)
  }

  /**
   * 获取歌曲在队列中的索引
   */
  getIndexOfSong(songId: number): number {
    return this.queue.findIndex(song => song.id === songId)
  }

  /**
   * 添加监听器
   */
  addListener(listener: PlayQueueChangeListener): void {
    this.listeners.push(listener)
  }

  /**
   * 移除监听器
   */
  removeListener(listener: PlayQueueChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index !== -1) {
      this.listeners.splice(index, 1)
    }
  }

  // ========== 通知方法 ==========

  private notifyQueueChanged(): void {
    for (const listener of this.listeners) {
      listener.onQueueChanged?.(this.queue)
    }
  }

  private notifyCurrentIndexChanged(): void {
    for (const listener of this.listeners) {
      listener.onCurrentIndexChanged?.(this.currentIndex)
    }
  }

  private notifyPlayModeChanged(): void {
    for (const listener of this.listeners) {
      listener.onPlayModeChanged?.(this.playMode)
    }
  }

  private notifySongRemoved(song: Song, index: number): void {
    for (const listener of this.listeners) {
      listener.onSongRemoved?.(song, index)
    }
  }

  private notifyQueueCleared(): void {
    for (const listener of this.listeners) {
      listener.onQueueCleared?.()
    }
  }
}
