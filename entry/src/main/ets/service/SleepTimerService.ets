import { AudioPlayerService } from './AudioPlayerService'
import { PreferencesManager } from '../data/preferences/PreferencesManager'

/**
 * 定时关闭监听器
 */
export interface SleepTimerListener {
  onTimerTick?: (remainingMs: number) => void
  onTimerExpired?: () => void
  onTimerCancelled?: () => void
}

/**
 * 定时关闭服务
 * 负责管理定时关闭功能
 */
export class SleepTimerService {
  private static instance: SleepTimerService | null = null
  private audioPlayerService: AudioPlayerService
  private preferencesManager: PreferencesManager
  private timerInterval: number = -1
  private endTime: number = 0
  private listeners: SleepTimerListener[] = []
  private isRunning: boolean = false

  private constructor() {
    this.audioPlayerService = AudioPlayerService.getInstance()
    this.preferencesManager = PreferencesManager.getInstance()
  }

  static getInstance(): SleepTimerService {
    if (!SleepTimerService.instance) {
      SleepTimerService.instance = new SleepTimerService()
    }
    return SleepTimerService.instance
  }

  /**
   * 初始化服务，恢复之前的定时器
   */
  async initialize(): Promise<void> {
    const remaining = await this.preferencesManager.getSleepTimerRemaining()
    if (remaining > 0) {
      this.endTime = Date.now() + remaining
      this.startTimer()
      console.info('SleepTimerService', `Restored timer with ${remaining}ms remaining`)
    }
  }

  /**
   * 设置定时关闭（分钟）
   */
  async setTimer(minutes: number): Promise<void> {
    // 取消现有定时器
    this.cancelTimer()

    if (minutes <= 0) {
      console.info('SleepTimerService', 'Timer disabled')
      return
    }

    // 设置新定时器
    this.endTime = Date.now() + minutes * 60 * 1000
    await this.preferencesManager.setSleepTimer(minutes)
    this.startTimer()

    console.info('SleepTimerService', `Timer set for ${minutes} minutes`)
  }

  /**
   * 取消定时器
   */
  async cancelTimer(): Promise<void> {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
      this.timerInterval = -1
    }
    this.isRunning = false
    this.endTime = 0
    await this.preferencesManager.cancelSleepTimer()
    this.notifyTimerCancelled()
    console.info('SleepTimerService', 'Timer cancelled')
  }

  /**
   * 获取剩余时间（毫秒）
   */
  getRemainingTime(): number {
    if (!this.isRunning || this.endTime <= 0) {
      return 0
    }
    const remaining = this.endTime - Date.now()
    return remaining > 0 ? remaining : 0
  }

  /**
   * 是否正在运行
   */
  isTimerRunning(): boolean {
    return this.isRunning
  }

  /**
   * 启动定时器
   */
  private startTimer(): void {
    if (this.timerInterval !== -1) {
      return
    }

    this.isRunning = true
    this.timerInterval = setInterval(() => {
      this.checkTimer()
    }, 1000)
  }

  /**
   * 检查定时器状态
   */
  private async checkTimer(): Promise<void> {
    const remaining = this.getRemainingTime()

    if (remaining <= 0) {
      // 定时器到期
      await this.onTimerExpired()
    } else {
      // 通知剩余时间
      this.notifyTimerTick(remaining)
    }
  }

  /**
   * 定时器到期处理
   */
  private async onTimerExpired(): Promise<void> {
    console.info('SleepTimerService', 'Timer expired, stopping playback')

    // 停止播放
    await this.audioPlayerService.stop()

    // 清理定时器
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
      this.timerInterval = -1
    }
    this.isRunning = false
    this.endTime = 0
    await this.preferencesManager.cancelSleepTimer()

    // 通知监听器
    this.notifyTimerExpired()
  }

  /**
   * 添加监听器
   */
  addListener(listener: SleepTimerListener): void {
    this.listeners.push(listener)
  }

  /**
   * 移除监听器
   */
  removeListener(listener: SleepTimerListener): void {
    const index = this.listeners.indexOf(listener)
    if (index !== -1) {
      this.listeners.splice(index, 1)
    }
  }

  // ========== 通知方法 ==========

  private notifyTimerTick(remainingMs: number): void {
    for (const listener of this.listeners) {
      listener.onTimerTick?.(remainingMs)
    }
  }

  private notifyTimerExpired(): void {
    for (const listener of this.listeners) {
      listener.onTimerExpired?.()
    }
  }

  private notifyTimerCancelled(): void {
    for (const listener of this.listeners) {
      listener.onTimerCancelled?.()
    }
  }

  /**
   * 释放资源
   */
  release(): void {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
      this.timerInterval = -1
    }
    this.listeners = []
    this.isRunning = false
  }
}
