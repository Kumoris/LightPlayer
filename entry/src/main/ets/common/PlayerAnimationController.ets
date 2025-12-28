import { AnimationState, PlayerState } from '../model/PlayState'
import { curves } from '@kit.ArkUI'

/**
 * 动效配置常量
 */
const DISC_ROTATION_DURATION: number = 20000  // 唱片旋转一圈时间（毫秒）
const DISC_SPIN_UP_DURATION: number = 800     // 启动加速时间
const DISC_SPIN_DOWN_DURATION: number = 600   // 减速停止时间
const PROGRESS_TICK_INTERVAL: number = 200    // 进度刷新间隔（毫秒）
const LOADING_PULSE_DURATION: number = 1000   // 加载脉冲动画时间

/**
 * 动效回调接口
 */
export interface AnimationCallback {
  onRotationUpdate?: (angle: number) => void
  onProgressTick?: () => void
  onAnimationStateChange?: (state: AnimationState) => void
  onLoadingPulse?: (scale: number) => void
}

/**
 * 播放器动效控制器
 * 只负责"怎么动"，不关心播放逻辑
 * 动效是状态的副作用，不主动触发
 */
export class PlayerAnimationController {
  private static instance: PlayerAnimationController | null = null

  // 当前动效状态
  private animState: AnimationState = AnimationState.IDLE
  // 唱片当前旋转角度
  private currentRotation: number = 0
  // 目标旋转速度（度/秒）
  private targetSpeed: number = 0
  // 当前旋转速度
  private currentSpeed: number = 0
  // 旋转动画定时器
  private rotationTimer: number = -1
  // 进度刷新定时器
  private progressTimer: number = -1
  // 加载动画定时器
  private loadingTimer: number = -1
  // 回调函数
  private callbacks: AnimationCallback = {}
  // 上一帧时间
  private lastFrameTime: number = 0
  // 加载脉冲相位
  private loadingPhase: number = 0

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): PlayerAnimationController {
    if (!PlayerAnimationController.instance) {
      PlayerAnimationController.instance = new PlayerAnimationController()
    }
    return PlayerAnimationController.instance
  }

  /**
   * 设置动效回调
   */
  setCallbacks(callbacks: AnimationCallback): void {
    this.callbacks = callbacks
  }

  /**
   * 获取当前动效状态
   */
  getAnimationState(): AnimationState {
    return this.animState
  }

  /**
   * 获取当前旋转角度
   */
  getCurrentRotation(): number {
    return this.currentRotation
  }

  /**
   * 根据播放状态更新动效
   * 这是状态机绑定的核心方法
   */
  updateForPlayerState(playerState: PlayerState): void {
    console.info('PlayerAnimationController', `updateForPlayerState: ${playerState}`)

    switch (playerState) {
      case PlayerState.PLAYING:
        this.startDiscRotation()
        this.startProgressTicker()
        this.stopLoadingAnimation()
        break

      case PlayerState.PAUSED:
        this.pauseDiscRotation()
        this.stopProgressTicker()
        this.stopLoadingAnimation()
        break

      case PlayerState.LOADING:
        this.stopDiscRotation()
        this.stopProgressTicker()
        this.startLoadingAnimation()
        break

      case PlayerState.IDLE:
      case PlayerState.STOPPED:
      case PlayerState.ERROR:
        this.stopAll()
        break

      case PlayerState.PREPARED:
        // 准备完成，等待播放指令
        this.stopLoadingAnimation()
        break
    }
  }

  /**
   * 启动唱片旋转动画
   * 使用鸿蒙弹簧曲线实现自然的加速效果
   */
  startDiscRotation(): void {
    if (this.animState === AnimationState.SPINNING) {
      return
    }

    console.info('PlayerAnimationController', 'startDiscRotation')

    // 计算目标速度：360度 / 旋转周期（秒）
    this.targetSpeed = 360 / (DISC_ROTATION_DURATION / 1000)
    this.animState = AnimationState.SPINNING
    this.lastFrameTime = Date.now()

    // 使用定时器模拟帧动画，实现平滑旋转
    if (this.rotationTimer === -1) {
      this.rotationTimer = setInterval(() => {
        this.updateRotation()
      }, 16) // 约60fps
    }

    this.notifyStateChange()
  }

  /**
   * 暂停唱片旋转（保持当前角度，平滑减速）
   */
  pauseDiscRotation(): void {
    if (this.animState !== AnimationState.SPINNING) {
      return
    }

    console.info('PlayerAnimationController', 'pauseDiscRotation')

    this.targetSpeed = 0
    this.animState = AnimationState.PAUSED

    this.notifyStateChange()
  }

  /**
   * 停止唱片旋转（重置角度）
   */
  stopDiscRotation(): void {
    console.info('PlayerAnimationController', 'stopDiscRotation')

    this.targetSpeed = 0
    this.currentSpeed = 0

    if (this.rotationTimer !== -1) {
      clearInterval(this.rotationTimer)
      this.rotationTimer = -1
    }

    // 重置角度
    this.currentRotation = 0
    this.animState = AnimationState.IDLE

    this.callbacks.onRotationUpdate?.(0)
    this.notifyStateChange()
  }

  /**
   * 更新旋转角度（每帧调用）
   * 实现平滑的加速/减速效果
   */
  private updateRotation(): void {
    const now = Date.now()
    const deltaTime = (now - this.lastFrameTime) / 1000 // 转换为秒
    this.lastFrameTime = now

    // 使用鸿蒙弹簧插值实现平滑的速度变化
    const speedDiff = this.targetSpeed - this.currentSpeed
    const acceleration = speedDiff * 3 // 弹簧系数

    this.currentSpeed += acceleration * deltaTime

    // 速度接近0时完全停止
    if (this.animState === AnimationState.PAUSED && Math.abs(this.currentSpeed) < 0.1) {
      this.currentSpeed = 0
      if (this.rotationTimer !== -1) {
        clearInterval(this.rotationTimer)
        this.rotationTimer = -1
      }
      return
    }

    // 更新角度
    this.currentRotation = (this.currentRotation + this.currentSpeed * deltaTime) % 360

    // 通知UI更新
    this.callbacks.onRotationUpdate?.(this.currentRotation)
  }

  /**
   * 启动进度刷新定时器
   */
  startProgressTicker(): void {
    if (this.progressTimer !== -1) {
      return
    }

    console.info('PlayerAnimationController', 'startProgressTicker')

    this.progressTimer = setInterval(() => {
      this.callbacks.onProgressTick?.()
    }, PROGRESS_TICK_INTERVAL)
  }

  /**
   * 停止进度刷新定时器
   */
  stopProgressTicker(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer)
      this.progressTimer = -1
    }
  }

  /**
   * 启动加载动画（呼吸脉冲效果）
   */
  startLoadingAnimation(): void {
    if (this.loadingTimer !== -1) {
      return
    }

    console.info('PlayerAnimationController', 'startLoadingAnimation')

    this.animState = AnimationState.LOADING
    this.loadingPhase = 0

    this.loadingTimer = setInterval(() => {
      // 使用正弦函数创建呼吸效果
      this.loadingPhase += (2 * Math.PI) / (LOADING_PULSE_DURATION / 16)
      const scale = 0.95 + 0.05 * Math.sin(this.loadingPhase)
      this.callbacks.onLoadingPulse?.(scale)
    }, 16)

    this.notifyStateChange()
  }

  /**
   * 停止加载动画
   */
  stopLoadingAnimation(): void {
    if (this.loadingTimer !== -1) {
      clearInterval(this.loadingTimer)
      this.loadingTimer = -1
    }
    this.callbacks.onLoadingPulse?.(1.0) // 恢复正常大小
  }

  /**
   * 停止所有动效
   */
  stopAll(): void {
    console.info('PlayerAnimationController', 'stopAll')

    this.stopDiscRotation()
    this.stopProgressTicker()
    this.stopLoadingAnimation()
    this.animState = AnimationState.IDLE
    this.notifyStateChange()
  }

  /**
   * 通知状态变化
   */
  private notifyStateChange(): void {
    this.callbacks.onAnimationStateChange?.(this.animState)
  }

  /**
   * 设置旋转角度（用于恢复状态）
   */
  setRotation(angle: number): void {
    this.currentRotation = angle % 360
    this.callbacks.onRotationUpdate?.(this.currentRotation)
  }

  /**
   * 释放资源
   */
  release(): void {
    this.stopAll()
    this.callbacks = {}
  }
}

/**
 * 创建鸿蒙弹簧曲线动画参数
 * 用于按钮点击、状态切换等场景
 */
export function createSpringCurve(): ICurve {
  return curves.springMotion(0.5, 0.8)
}

/**
 * 创建阻尼弹簧曲线（用于更柔和的动效）
 */
export function createDampedSpringCurve(): ICurve {
  return curves.responsiveSpringMotion(0.35, 0.9)
}

/**
 * 创建快速响应曲线（用于按钮反馈）
 */
export function createQuickResponseCurve(): ICurve {
  return curves.interpolatingSpring(0, 1, 400, 38)
}
