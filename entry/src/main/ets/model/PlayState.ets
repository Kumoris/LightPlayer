/**
 * 播放模式枚举
 */
export enum PlayMode {
  SEQUENCE = 0,    // 顺序播放
  LOOP = 1,        // 列表循环
  SINGLE = 2,      // 单曲循环
  SHUFFLE = 3      // 随机播放
}

/**
 * 播放状态枚举
 */
export enum PlayerState {
  IDLE = 'idle',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
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
