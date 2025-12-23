import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
import { PlayMode } from '../../model/PlayState'

/**
 * 偏好设置Key常量
 */
const PREFERENCES_NAME = 'music_player_preferences'

const KEY_PLAY_MODE = 'play_mode'
const KEY_LAST_SONG_ID = 'last_song_id'
const KEY_LAST_POSITION = 'last_position'
const KEY_VOLUME = 'volume'
const KEY_SCAN_PATHS = 'scan_paths'
const KEY_FIRST_LAUNCH = 'first_launch'
const KEY_PLAY_HISTORY = 'play_history'
const KEY_SEARCH_HISTORY = 'search_history'
const KEY_SLEEP_TIMER = 'sleep_timer'
const KEY_SLEEP_TIMER_END = 'sleep_timer_end'
const KEY_AUDIO_QUALITY = 'audio_quality'
const KEY_LAST_PLAYLIST_JSON = 'last_playlist_json'

/**
 * 播放历史项
 */
export interface PlayHistoryItem {
  songId: number
  playTime: number
  playCount: number
}

/**
 * 音质设置
 */
export enum AudioQuality {
  LOW = 0,
  MEDIUM = 1,
  HIGH = 2,
  LOSSLESS = 3
}

/**
 * 偏好设置管理器
 * 负责应用设置的持久化存储
 */
export class PreferencesManager {
  private static instance: PreferencesManager | null = null
  private preferences: preferences.Preferences | null = null
  private context: Context | null = null
  private initialized: boolean = false

  private constructor() {}

  static getInstance(): PreferencesManager {
    if (!PreferencesManager.instance) {
      PreferencesManager.instance = new PreferencesManager()
    }
    return PreferencesManager.instance
  }

  /**
   * 初始化偏好设置
   */
  async initialize(context: Context): Promise<boolean> {
    this.context = context
    try {
      this.preferences = await preferences.getPreferences(context, PREFERENCES_NAME)
      this.initialized = true
      return true
    } catch (error) {
      console.error('PreferencesManager', `Initialize preferences failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized
  }

  /**
   * 获取播放模式
   */
  async getPlayMode(): Promise<PlayMode> {
    if (!this.preferences) {
      return PlayMode.SEQUENCE
    }
    try {
      const value = await this.preferences.get(KEY_PLAY_MODE, PlayMode.SEQUENCE)
      return value as PlayMode
    } catch (error) {
      console.error('PreferencesManager', `Get play mode failed: ${JSON.stringify(error)}`)
      return PlayMode.SEQUENCE
    }
  }

  /**
   * 设置播放模式
   */
  async setPlayMode(mode: PlayMode): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_PLAY_MODE, mode)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set play mode failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取上次播放的歌曲ID
   */
  async getLastSongId(): Promise<number> {
    if (!this.preferences) {
      return -1
    }
    try {
      const value = await this.preferences.get(KEY_LAST_SONG_ID, -1)
      return value as number
    } catch (error) {
      console.error('PreferencesManager', `Get last song id failed: ${JSON.stringify(error)}`)
      return -1
    }
  }

  /**
   * 设置上次播放的歌曲ID
   */
  async setLastSongId(songId: number): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_LAST_SONG_ID, songId)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set last song id failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取上次播放位置
   */
  async getLastPosition(): Promise<number> {
    if (!this.preferences) {
      return 0
    }
    try {
      const value = await this.preferences.get(KEY_LAST_POSITION, 0)
      return value as number
    } catch (error) {
      console.error('PreferencesManager', `Get last position failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 设置上次播放位置
   */
  async setLastPosition(position: number): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_LAST_POSITION, position)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set last position failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取音量
   */
  async getVolume(): Promise<number> {
    if (!this.preferences) {
      return 100
    }
    try {
      const value = await this.preferences.get(KEY_VOLUME, 100)
      return value as number
    } catch (error) {
      console.error('PreferencesManager', `Get volume failed: ${JSON.stringify(error)}`)
      return 100
    }
  }

  /**
   * 设置音量
   */
  async setVolume(volume: number): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_VOLUME, volume)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set volume failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取扫描路径列表
   */
  async getScanPaths(): Promise<string[]> {
    if (!this.preferences) {
      return []
    }
    try {
      const value = await this.preferences.get(KEY_SCAN_PATHS, '[]')
      return JSON.parse(value as string) as string[]
    } catch (error) {
      console.error('PreferencesManager', `Get scan paths failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 设置扫描路径列表
   */
  async setScanPaths(paths: string[]): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_SCAN_PATHS, JSON.stringify(paths))
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set scan paths failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 是否首次启动
   */
  async isFirstLaunch(): Promise<boolean> {
    if (!this.preferences) {
      return true
    }
    try {
      const value = await this.preferences.get(KEY_FIRST_LAUNCH, true)
      return value as boolean
    } catch (error) {
      console.error('PreferencesManager', `Get first launch failed: ${JSON.stringify(error)}`)
      return true
    }
  }

  /**
   * 设置首次启动标志
   */
  async setFirstLaunch(isFirst: boolean): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_FIRST_LAUNCH, isFirst)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set first launch failed: ${JSON.stringify(error)}`)
    }
  }

  // ========== 播放历史相关 ==========

  /**
   * 获取播放历史
   */
  async getPlayHistory(): Promise<PlayHistoryItem[]> {
    if (!this.preferences) {
      return []
    }
    try {
      const value = await this.preferences.get(KEY_PLAY_HISTORY, '[]')
      return JSON.parse(value as string) as PlayHistoryItem[]
    } catch (error) {
      console.error('PreferencesManager', `Get play history failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 添加播放历史
   */
  async addPlayHistory(songId: number): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      const history = await this.getPlayHistory()
      const existingIndex = history.findIndex(item => item.songId === songId)

      if (existingIndex >= 0) {
        // 已存在，更新播放时间和次数
        history[existingIndex].playTime = Date.now()
        history[existingIndex].playCount += 1
        // 移到最前面
        const item = history.splice(existingIndex, 1)[0]
        history.unshift(item)
      } else {
        // 新增记录
        history.unshift({
          songId: songId,
          playTime: Date.now(),
          playCount: 1
        })
      }

      // 限制历史记录数量（最多100条）
      const trimmedHistory = history.slice(0, 100)

      await this.preferences.put(KEY_PLAY_HISTORY, JSON.stringify(trimmedHistory))
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Add play history failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 清空播放历史
   */
  async clearPlayHistory(): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_PLAY_HISTORY, '[]')
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Clear play history failed: ${JSON.stringify(error)}`)
    }
  }

  // ========== 搜索历史相关 ==========

  /**
   * 获取搜索历史
   */
  async getSearchHistory(): Promise<string[]> {
    if (!this.preferences) {
      return []
    }
    try {
      const value = await this.preferences.get(KEY_SEARCH_HISTORY, '[]')
      return JSON.parse(value as string) as string[]
    } catch (error) {
      console.error('PreferencesManager', `Get search history failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 添加搜索历史
   */
  async addSearchHistory(keyword: string): Promise<void> {
    if (!this.preferences || !keyword.trim()) {
      return
    }
    try {
      const history = await this.getSearchHistory()

      // 移除已存在的相同关键词
      const filteredHistory = history.filter(item => item !== keyword.trim())

      // 添加到最前面
      filteredHistory.unshift(keyword.trim())

      // 限制历史记录数量（最多20条）
      const trimmedHistory = filteredHistory.slice(0, 20)

      await this.preferences.put(KEY_SEARCH_HISTORY, JSON.stringify(trimmedHistory))
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Add search history failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 删除单条搜索历史
   */
  async removeSearchHistory(keyword: string): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      const history = await this.getSearchHistory()
      const filteredHistory = history.filter(item => item !== keyword)
      await this.preferences.put(KEY_SEARCH_HISTORY, JSON.stringify(filteredHistory))
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Remove search history failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 清空搜索历史
   */
  async clearSearchHistory(): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_SEARCH_HISTORY, '[]')
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Clear search history failed: ${JSON.stringify(error)}`)
    }
  }

  // ========== 定时关闭相关 ==========

  /**
   * 设置定时关闭（分钟）
   */
  async setSleepTimer(minutes: number): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      const endTime = minutes > 0 ? Date.now() + minutes * 60 * 1000 : 0
      await this.preferences.put(KEY_SLEEP_TIMER, minutes)
      await this.preferences.put(KEY_SLEEP_TIMER_END, endTime)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set sleep timer failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取定时关闭剩余时间（毫秒）
   */
  async getSleepTimerRemaining(): Promise<number> {
    if (!this.preferences) {
      return 0
    }
    try {
      const endTime = await this.preferences.get(KEY_SLEEP_TIMER_END, 0) as number
      if (endTime <= 0) {
        return 0
      }
      const remaining = endTime - Date.now()
      return remaining > 0 ? remaining : 0
    } catch (error) {
      console.error('PreferencesManager', `Get sleep timer remaining failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 取消定时关闭
   */
  async cancelSleepTimer(): Promise<void> {
    await this.setSleepTimer(0)
  }

  // ========== 音质设置相关 ==========

  /**
   * 获取音质设置
   */
  async getAudioQuality(): Promise<AudioQuality> {
    if (!this.preferences) {
      return AudioQuality.HIGH
    }
    try {
      const value = await this.preferences.get(KEY_AUDIO_QUALITY, AudioQuality.HIGH)
      return value as AudioQuality
    } catch (error) {
      console.error('PreferencesManager', `Get audio quality failed: ${JSON.stringify(error)}`)
      return AudioQuality.HIGH
    }
  }

  /**
   * 设置音质
   */
  async setAudioQuality(quality: AudioQuality): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_AUDIO_QUALITY, quality)
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Set audio quality failed: ${JSON.stringify(error)}`)
    }
  }

  // ========== 播放列表持久化 ==========

  /**
   * 保存上次播放列表
   */
  async saveLastPlaylist(songIds: number[]): Promise<void> {
    if (!this.preferences) {
      return
    }
    try {
      await this.preferences.put(KEY_LAST_PLAYLIST_JSON, JSON.stringify(songIds))
      await this.preferences.flush()
    } catch (error) {
      console.error('PreferencesManager', `Save last playlist failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取上次播放列表
   */
  async getLastPlaylist(): Promise<number[]> {
    if (!this.preferences) {
      return []
    }
    try {
      const value = await this.preferences.get(KEY_LAST_PLAYLIST_JSON, '[]')
      return JSON.parse(value as string) as number[]
    } catch (error) {
      console.error('PreferencesManager', `Get last playlist failed: ${JSON.stringify(error)}`)
      return []
    }
  }
}
