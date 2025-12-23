/**
 * 应用常量定义
 */
export class AppConstants {
  // 应用信息
  static readonly APP_NAME = 'MusicPlayer'
  static readonly APP_VERSION = '1.0.0'

  // 页面路由
  static readonly ROUTER_MAIN = 'pages/Index'
  static readonly ROUTER_PLAYER = 'pages/PlayerPage'
  static readonly ROUTER_PLAYLIST = 'pages/PlaylistPage'
  static readonly ROUTER_SETTINGS = 'pages/SettingsPage'
  static readonly ROUTER_SEARCH = 'pages/SearchPage'

  // 日志TAG
  static readonly LOG_TAG = 'MusicPlayer'
  static readonly LOG_DOMAIN = 0x0001

  // 数据库
  static readonly DB_NAME = 'MusicPlayer.db'
  static readonly DB_VERSION = 1

  // 偏好设置
  static readonly PREFERENCES_NAME = 'music_player_preferences'

  // 默认扫描路径
  static readonly DEFAULT_SCAN_PATHS = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download'
  ]

  // 支持的音频格式
  static readonly SUPPORTED_AUDIO_FORMATS = [
    '.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a', '.wma'
  ]

  // UI相关
  static readonly MINI_PLAYER_HEIGHT = 60
  static readonly TAB_BAR_HEIGHT = 56
  static readonly PLAYER_CONTROL_SIZE = 48
}
