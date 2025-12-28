/**
 * 播放模式枚举
 */
export enum PlayMode {
  SEQUENCE = 0,       // 顺序播放
  LOOP = 1,           // 列表循环
  SINGLE = 2,         // 单曲循环
  SHUFFLE = 3,        // 随机播放
  SMART_SHUFFLE = 4,  // 智能随机（避免同专辑/风格连续）
  TIME_AWARE = 5,     // 时间感知（根据时段选歌）
  NIGHT_MODE = 6      // 夜间模式（舒缓 + 渐弱）
}

/**
 * 播放状态枚举
 * 作为全播放器唯一真相，UI/动效/播放逻辑都只看它
 */
export enum PlayerState {
  IDLE = 'idle',           // 空闲状态
  LOADING = 'loading',     // 加载中（准备播放）
  PREPARED = 'prepared',   // 已准备好
  PLAYING = 'playing',     // 正在播放
  PAUSED = 'paused',       // 已暂停
  STOPPED = 'stopped',     // 已停止
  ERROR = 'error'          // 错误状态
}

/**
 * 动效状态枚举
 * 用于控制播放器动效的状态
 */
export enum AnimationState {
  IDLE = 'idle',           // 空闲（无动效）
  SPINNING = 'spinning',   // 旋转中
  PAUSED = 'paused',       // 暂停（保持角度）
  LOADING = 'loading'      // 加载动画
}

/**
 * 播放状态数据模型
 */
@Observed
export class PlayState {
  currentSongId: number = -1
  playerState: PlayerState = PlayerState.IDLE
  playMode: PlayMode = PlayMode.SEQUENCE
  currentPosition: number = 0 // 当前播放位置（毫秒）
  duration: number = 0 // 总时长（毫秒）
  volume: number = 100 // 音量 0-100

  /**
   * 获取播放进度百分比
   */
  getProgress(): number {
    if (this.duration === 0) {
      return 0
    }
    return (this.currentPosition / this.duration) * 100
  }

  /**
   * 是否正在播放
   */
  isPlaying(): boolean {
    return this.playerState === PlayerState.PLAYING
  }
}
