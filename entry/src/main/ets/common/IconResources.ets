/**
 * 图标资源管理器
 * 为智能播放模式提供SVG图标路径
 */
export class IconResources {
  /**
   * 获取智能随机图标路径 (脑+随机符号)
   * 返回 SVG path data
   */
  static getSmartShuffleIconPath(): string {
    return 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z'
  }

  /**
   * 获取时间感知图标路径 (时钟+太阳/月亮)
   */
  static getTimeAwareIconPath(): string {
    return 'M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z'
  }

  /**
   * 获取夜间模式图标路径 (月亮+星星)
   */
  static getNightModeIconPath(): string {
    return 'M9 2c-1.05 0-2.05.16-3 .46 4.06 1.27 7 5.06 7 9.54 0 4.48-2.94 8.27-7 9.54.95.3 1.95.46 3 .46 5.52 0 10-4.48 10-10S14.52 2 9 2z'
  }

  /**
   * 获取流派统计图标路径
   */
  static getGenreStatsIconPath(): string {
    return 'M5 9.2h3V19H5zM10.6 5h2.8v14h-2.8zm5.6 8H19v6h-2.8z'
  }

  /**
   * 获取编辑元数据图标路径
   */
  static getEditMetadataIconPath(): string {
    return 'M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z'
  }
}

/**
 * SVG图标组件构建器
 */
export class SvgIconBuilder {
  /**
   * 创建智能随机图标
   */
  @Builder
  static SmartShuffleIcon(size: number = 24, color: string = '#666666') {
    Path()
      .width(size)
      .height(size)
      .commands(IconResources.getSmartShuffleIconPath())
      .fillOpacity(1)
      .fill(color)
  }

  /**
   * 创建时间感知图标
   */
  @Builder
  static TimeAwareIcon(size: number = 24, color: string = '#666666') {
    Path()
      .width(size)
      .height(size)
      .commands(IconResources.getTimeAwareIconPath())
      .fillOpacity(1)
      .fill(color)
  }

  /**
   * 创建夜间模式图标
   */
  @Builder
  static NightModeIcon(size: number = 24, color: string = '#666666') {
    Path()
      .width(size)
      .height(size)
      .commands(IconResources.getNightModeIconPath())
      .fillOpacity(1)
      .fill(color)
  }

  /**
   * 创建流派统计图标
   */
  @Builder
  static GenreStatsIcon(size: number = 24, color: string = '#666666') {
    Path()
      .width(size)
      .height(size)
      .commands(IconResources.getGenreStatsIconPath())
      .fillOpacity(1)
      .fill(color)
  }

  /**
   * 创建编辑元数据图标
   */
  @Builder
  static EditMetadataIcon(size: number = 24, color: string = '#666666') {
    Path()
      .width(size)
      .height(size)
      .commands(IconResources.getEditMetadataIconPath())
      .fillOpacity(1)
      .fill(color)
  }
}
