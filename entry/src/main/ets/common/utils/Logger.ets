import { hilog } from '@kit.PerformanceAnalysisKit'
import { AppConstants } from '../constants/AppConstants'

/**
 * 日志工具类
 */
export class Logger {
  private static domain: number = AppConstants.LOG_DOMAIN
  private static tag: string = AppConstants.LOG_TAG

  /**
   * Debug日志
   */
  static debug(message: string, ...args: Object[]): void {
    hilog.debug(Logger.domain, Logger.tag, message, args)
  }

  /**
   * Info日志
   */
  static info(message: string, ...args: Object[]): void {
    hilog.info(Logger.domain, Logger.tag, message, args)
  }

  /**
   * Warn日志
   */
  static warn(message: string, ...args: Object[]): void {
    hilog.warn(Logger.domain, Logger.tag, message, args)
  }

  /**
   * Error日志
   */
  static error(message: string, ...args: Object[]): void {
    hilog.error(Logger.domain, Logger.tag, message, args)
  }

  /**
   * Fatal日志
   */
  static fatal(message: string, ...args: Object[]): void {
    hilog.fatal(Logger.domain, Logger.tag, message, args)
  }
}
