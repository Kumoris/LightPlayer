import { PlayerState, AnimationState } from '../model/PlayState'
import { PlayerAnimationController, AnimationCallback } from './PlayerAnimationController'
import { PlayStateKeys } from './GlobalPlayState'

/**
 * 动效绑定回调接口
 */
export interface EffectBinderCallback {
  onRotationChange: (angle: number) => void
  onLoadingScaleChange: (scale: number) => void
  onAnimationStateChange: (state: AnimationState) => void
}

/**
 * 播放器动效绑定器
 * 负责将播放状态与动效控制器绑定
 * 动效永远不主动，只作为 PlayerState 的副作用
 */
export class PlayerEffectBinder {
  private animController: PlayerAnimationController
  private callback: EffectBinderCallback
  private lastPlayerState: PlayerState = PlayerState.IDLE
  private isActive: boolean = false

  constructor(callback: EffectBinderCallback) {
    this.animController = PlayerAnimationController.getInstance()
    this.callback = callback
    this.setupAnimationCallbacks()
  }

  /**
   * 设置动效回调
   */
  private setupAnimationCallbacks(): void {
    const animCallbacks: AnimationCallback = {
      onRotationUpdate: (angle: number) => {
        this.callback.onRotationChange(angle)
      },
      onLoadingPulse: (scale: number) => {
        this.callback.onLoadingScaleChange(scale)
      },
      onAnimationStateChange: (state: AnimationState) => {
        this.callback.onAnimationStateChange(state)
      },
      onProgressTick: () => {
        // 进度刷新由 PlayController 处理
      }
    }
    this.animController.setCallbacks(animCallbacks)
  }

  /**
   * 激活绑定器（在组件 aboutToAppear 时调用）
   */
  activate(): void {
    if (this.isActive) {
      return
    }
    this.isActive = true
    console.info('PlayerEffectBinder', 'activated')

    // 读取当前播放状态并同步动效
    const isPlaying = AppStorage.get<boolean>(PlayStateKeys.IS_PLAYING) ?? false
    const isLoading = AppStorage.get<boolean>(PlayStateKeys.IS_LOADING) ?? false

    if (isLoading) {
      this.updateForPlayerState(PlayerState.LOADING)
    } else if (isPlaying) {
      this.updateForPlayerState(PlayerState.PLAYING)
    } else {
      this.updateForPlayerState(PlayerState.PAUSED)
    }
  }

  /**
   * 停用绑定器（在组件 aboutToDisappear 时调用）
   */
  deactivate(): void {
    if (!this.isActive) {
      return
    }
    this.isActive = false
    console.info('PlayerEffectBinder', 'deactivated')
  }

  /**
   * 根据播放状态更新动效
   * 这是状态机绑定的核心方法
   */
  updateForPlayerState(state: PlayerState): void {
    if (!this.isActive) {
      return
    }

    // 避免重复处理相同状态
    if (state === this.lastPlayerState) {
      return
    }

    console.info('PlayerEffectBinder', `State changed: ${this.lastPlayerState} -> ${state}`)
    this.lastPlayerState = state

    // 委托给动效控制器处理
    this.animController.updateForPlayerState(state)
  }

  /**
   * 根据 isPlaying 和 isLoading 状态推断 PlayerState
   * 用于监听 AppStorage 变化时调用
   */
  updateFromPlayingState(isPlaying: boolean, isLoading: boolean): void {
    let state: PlayerState

    if (isLoading) {
      state = PlayerState.LOADING
    } else if (isPlaying) {
      state = PlayerState.PLAYING
    } else {
      state = PlayerState.PAUSED
    }

    this.updateForPlayerState(state)
  }

  /**
   * 获取当前旋转角度
   */
  getCurrentRotation(): number {
    return this.animController.getCurrentRotation()
  }

  /**
   * 获取当前动效状态
   */
  getAnimationState(): AnimationState {
    return this.animController.getAnimationState()
  }

  /**
   * 释放资源
   */
  release(): void {
    this.deactivate()
  }
}

/**
 * 工厂函数：创建动效绑定器
 */
export function createPlayerEffectBinder(callback: EffectBinderCallback): PlayerEffectBinder {
  return new PlayerEffectBinder(callback)
}
