import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { wantAgent, WantAgent } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { deviceInfo } from '@kit.BasicServicesKit'

/**
 * 后台任务管理器
 * 负责管理应用的后台运行任务，确保音乐播放能在后台继续
 */
export class BackgroundTaskManager {
  private static instance: BackgroundTaskManager | null = null
  private isRunning: boolean = false
  private context: Context | null = null
  private isSupported: boolean = false

  private constructor() {
    // 检查设备是否支持后台任务
    try {
      this.isSupported = canIUse('SystemCapability.ResourceSchedule.BackgroundTaskManager.ContinuousTask')
    } catch (e) {
      this.isSupported = false
      console.warn('BackgroundTaskManager', 'Device capability check failed, assuming not supported')
    }
  }

  /**
   * 获取单例实例
   */
  static getInstance(): BackgroundTaskManager {
    if (!BackgroundTaskManager.instance) {
      BackgroundTaskManager.instance = new BackgroundTaskManager()
    }
    return BackgroundTaskManager.instance
  }

  /**
   * 初始化后台任务管理器
   * @param context 应用上下文
   */
  initialize(context: Context): void {
    this.context = context
    console.info('BackgroundTaskManager', 'Initialized')
  }

  /**
   * 启动后台运行任务
   * 当开始播放音乐时调用
   */
  async startBackgroundRunning(): Promise<boolean> {
    if (this.isRunning) {
      console.info('BackgroundTaskManager', 'Background task already running')
      return true
    }

    if (!this.context) {
      console.error('BackgroundTaskManager', 'Context not initialized')
      return false
    }

    // 检查设备是否支持
    if (!this.isSupported) {
      console.warn('BackgroundTaskManager', 'Background task not supported on this device')
      return false
    }

    try {
      // 创建 WantAgent，用于点击通知时返回应用
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.example.myapplication',
            abilityName: 'EntryAbility'
          }
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      }

      const agent: WantAgent = await wantAgent.getWantAgent(wantAgentInfo)

      // 启动后台长时任务
      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
        agent
      )

      this.isRunning = true
      console.info('BackgroundTaskManager', 'Background running started successfully')
      return true
    } catch (error) {
      const err = error as BusinessError
      console.error('BackgroundTaskManager', `Failed to start background running: ${err.code} - ${err.message}`)
      return false
    }
  }

  /**
   * 停止后台运行任务
   * 当停止播放音乐时调用
   */
  async stopBackgroundRunning(): Promise<boolean> {
    if (!this.isRunning) {
      console.info('BackgroundTaskManager', 'Background task not running')
      return true
    }

    if (!this.context) {
      console.error('BackgroundTaskManager', 'Context not initialized')
      return false
    }

    // 检查设备是否支持
    if (!this.isSupported) {
      console.warn('BackgroundTaskManager', 'Background task not supported on this device')
      return false
    }

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      this.isRunning = false
      console.info('BackgroundTaskManager', 'Background running stopped successfully')
      return true
    } catch (error) {
      const err = error as BusinessError
      console.error('BackgroundTaskManager', `Failed to stop background running: ${err.code} - ${err.message}`)
      return false
    }
  }

  /**
   * 检查后台任务是否正在运行
   */
  isBackgroundRunning(): boolean {
    return this.isRunning
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    await this.stopBackgroundRunning()
    this.context = null
    console.info('BackgroundTaskManager', 'Released')
  }
}
