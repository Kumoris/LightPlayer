import { audio } from '@kit.AudioKit'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * 音频焦点变化类型
 */
export enum AudioFocusChange {
  // 获得焦点
  GAIN = 1,
  // 失去焦点（短暂）- 应暂停并准备恢复
  LOSS_TRANSIENT = 2,
  // 失去焦点（永久）- 应停止播放
  LOSS = 3,
  // 失去焦点但可降低音量继续播放（如导航提示）
  LOSS_TRANSIENT_CAN_DUCK = 4
}

/**
 * 音频焦点事件监听器
 */
export interface AudioFocusListener {
  onFocusChange: (change: AudioFocusChange) => void
}

/**
 * 音频焦点管理器
 * 负责管理音频焦点，处理来电、其他应用播放音频等场景
 */
export class AudioFocusManager {
  private static instance: AudioFocusManager | null = null
  private audioRenderer: audio.AudioRenderer | null = null
  private listener: AudioFocusListener | null = null
  private hasFocus: boolean = false
  private wasPlayingBeforeLoss: boolean = false

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): AudioFocusManager {
    if (!AudioFocusManager.instance) {
      AudioFocusManager.instance = new AudioFocusManager()
    }
    return AudioFocusManager.instance
  }

  /**
   * 设置焦点变化监听器
   */
  setFocusListener(listener: AudioFocusListener): void {
    this.listener = listener
  }

  /**
   * 初始化音频焦点管理
   * 监听音频中断事件
   */
  async initialize(): Promise<boolean> {
    try {
      // 创建 AudioRenderer 配置
      const audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      }

      const audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels: audio.AudioChannel.CHANNEL_2,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      }

      const audioRendererOptions: audio.AudioRendererOptions = {
        streamInfo: audioStreamInfo,
        rendererInfo: audioRendererInfo
      }

      // 创建 AudioRenderer 用于监听中断
      this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions)

      // 注册中断事件监听
      this.audioRenderer.on('audioInterrupt', (interruptEvent: audio.InterruptEvent) => {
        this.handleAudioInterrupt(interruptEvent)
      })

      console.info('AudioFocusManager', 'Initialized successfully')
      return true
    } catch (error) {
      const err = error as BusinessError
      console.error('AudioFocusManager', `Failed to initialize: ${err.code} - ${err.message}`)
      return false
    }
  }

  /**
   * 处理音频中断事件
   */
  private handleAudioInterrupt(event: audio.InterruptEvent): void {
    console.info('AudioFocusManager', `Audio interrupt: forceType=${event.forceType}, hintType=${event.hintType}`)

    // 根据中断类型处理
    switch (event.hintType) {
      case audio.InterruptHint.INTERRUPT_HINT_PAUSE:
        // 被强制暂停（如来电）
        console.info('AudioFocusManager', 'Interrupt: should pause')
        this.wasPlayingBeforeLoss = this.hasFocus
        this.hasFocus = false
        this.notifyFocusChange(AudioFocusChange.LOSS_TRANSIENT)
        break

      case audio.InterruptHint.INTERRUPT_HINT_STOP:
        // 被强制停止
        console.info('AudioFocusManager', 'Interrupt: should stop')
        this.hasFocus = false
        this.notifyFocusChange(AudioFocusChange.LOSS)
        break

      case audio.InterruptHint.INTERRUPT_HINT_DUCK:
        // 需要降低音量（如导航提示）
        console.info('AudioFocusManager', 'Interrupt: should duck')
        this.notifyFocusChange(AudioFocusChange.LOSS_TRANSIENT_CAN_DUCK)
        break

      case audio.InterruptHint.INTERRUPT_HINT_UNDUCK:
        // 恢复正常音量
        console.info('AudioFocusManager', 'Interrupt: unduck')
        // 不需要特殊处理，音量会自动恢复
        break

      case audio.InterruptHint.INTERRUPT_HINT_RESUME:
        // 可以恢复播放（如来电结束）
        console.info('AudioFocusManager', 'Interrupt: can resume')
        if (this.wasPlayingBeforeLoss) {
          this.hasFocus = true
          this.notifyFocusChange(AudioFocusChange.GAIN)
        }
        break

      default:
        console.info('AudioFocusManager', `Unknown interrupt hint: ${event.hintType}`)
    }
  }

  /**
   * 通知焦点变化
   */
  private notifyFocusChange(change: AudioFocusChange): void {
    if (this.listener) {
      this.listener.onFocusChange(change)
    }
  }

  /**
   * 请求音频焦点
   */
  requestFocus(): void {
    this.hasFocus = true
    console.info('AudioFocusManager', 'Focus requested')
  }

  /**
   * 放弃音频焦点
   */
  abandonFocus(): void {
    this.hasFocus = false
    this.wasPlayingBeforeLoss = false
    console.info('AudioFocusManager', 'Focus abandoned')
  }

  /**
   * 标记正在播放状态（用于中断恢复）
   */
  setPlaying(isPlaying: boolean): void {
    if (isPlaying) {
      this.requestFocus()
    }
  }

  /**
   * 是否拥有焦点
   */
  hasAudioFocus(): boolean {
    return this.hasFocus
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    if (this.audioRenderer) {
      try {
        this.audioRenderer.off('audioInterrupt')
        await this.audioRenderer.release()
        this.audioRenderer = null
        console.info('AudioFocusManager', 'Released')
      } catch (error) {
        const err = error as BusinessError
        console.error('AudioFocusManager', `Failed to release: ${err.code} - ${err.message}`)
      }
    }
    this.listener = null
    this.hasFocus = false
  }
}
