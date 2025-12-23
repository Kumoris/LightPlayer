/**
 * 时间格式化工具类
 */
export class TimeUtils {
  /**
   * 将毫秒转换为 mm:ss 格式
   */
  static formatDuration(ms: number): string {
    if (ms < 0) {
      return '0:00'
    }
    const minutes = Math.floor(ms / 60000)
    const seconds = Math.floor((ms % 60000) / 1000)
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 将毫秒转换为 hh:mm:ss 格式
   */
  static formatDurationLong(ms: number): string {
    if (ms < 0) {
      return '0:00:00'
    }
    const hours = Math.floor(ms / 3600000)
    const minutes = Math.floor((ms % 3600000) / 60000)
    const seconds = Math.floor((ms % 60000) / 1000)

    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    }
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  /**
   * 获取当前时间戳
   */
  static now(): number {
    return Date.now()
  }

  /**
   * 格式化日期
   */
  static formatDate(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  /**
   * 格式化日期时间
   */
  static formatDateTime(timestamp: number): string {
    const date = new Date(timestamp)
    const dateStr = TimeUtils.formatDate(timestamp)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${dateStr} ${hours}:${minutes}`
  }
}
