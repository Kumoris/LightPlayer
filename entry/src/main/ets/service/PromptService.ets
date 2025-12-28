import { promptAction } from '@kit.ArkUI'
import { PlayMode } from '../model/PlayState'

/**
 * 播放模式信息接口
 */
interface PlayModeInfo {
  name: string
  icon: string
  description: string
}

/**
 * 提示服务
 * 提供统一的 Toast、对话框等提示功能
 */
export class PromptService {
  private static instance: PromptService | null = null

  private constructor() {}

  static getInstance(): PromptService {
    if (!PromptService.instance) {
      PromptService.instance = new PromptService()
    }
    return PromptService.instance
  }

  /**
   * 显示 Toast 提示
   * @param message 提示消息
   * @param duration 显示时长（毫秒），默认 2000ms
   */
  showToast(message: string, duration: number = 2000): void {
    try {
      promptAction.showToast({
        message: message,
        duration: duration,
        bottom: 100
      })
    } catch (error) {
      console.error('PromptService', `Show toast failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 显示播放模式切换提示
   * @param playMode 新的播放模式
   */
  showPlayModeToast(playMode: PlayMode): void {
    const modeInfo = this.getPlayModeInfo(playMode)
    this.showToast(`${modeInfo.icon} ${modeInfo.name}\n${modeInfo.description}`, 2000)
  }

  /**
   * 获取播放模式信息
   */
  private getPlayModeInfo(playMode: PlayMode): PlayModeInfo {
    switch (playMode) {
      case PlayMode.SEQUENCE:
        const sequenceInfo: PlayModeInfo = {
          name: '顺序播放',
          icon: '▶️',
          description: '按列表顺序播放歌曲'
        }
        return sequenceInfo
      case PlayMode.LOOP:
        const loopInfo: PlayModeInfo = {
          name: '列表循环',
          icon: '🔁',
          description: '播放完后重新开始'
        }
        return loopInfo
      case PlayMode.SINGLE:
        const singleInfo: PlayModeInfo = {
          name: '单曲循环',
          icon: '🔂',
          description: '重复播放当前歌曲'
        }
        return singleInfo
      case PlayMode.SMART_SHUFFLE:
        const smartShuffleInfo: PlayModeInfo = {
          name: '智能随机',
          icon: '🧠',
          description: '避免同风格/专辑连续播放'
        }
        return smartShuffleInfo
      case PlayMode.TIME_AWARE:
        const timeAwareInfo: PlayModeInfo = {
          name: '时间感知',
          icon: '🕒',
          description: '根据时段智能选歌'
        }
        return timeAwareInfo
      case PlayMode.NIGHT_MODE:
        const nightModeInfo: PlayModeInfo = {
          name: '夜间模式',
          icon: '🌙',
          description: '舒缓音乐，音量渐弱'
        }
        return nightModeInfo
      default:
        const defaultInfo: PlayModeInfo = {
          name: '顺序播放',
          icon: '▶️',
          description: '按列表顺序播放歌曲'
        }
        return defaultInfo
    }
  }

  /**
   * 显示错误提示
   */
  showError(message: string): void {
    this.showToast(`❌ ${message}`, 2500)
  }

  /**
   * 显示成功提示
   */
  showSuccess(message: string): void {
    this.showToast(`✅ ${message}`, 2000)
  }

  /**
   * 显示信息提示
   */
  showInfo(message: string): void {
    this.showToast(`ℹ️ ${message}`, 2000)
  }

  /**
   * 显示警告提示
   */
  showWarning(message: string): void {
    this.showToast(`⚠️ ${message}`, 2500)
  }
}
