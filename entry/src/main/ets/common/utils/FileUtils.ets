/**
 * 文件工具类
 */
export class FileUtils {
  /**
   * 获取文件扩展名
   */
  static getExtension(filePath: string): string {
    const lastDot = filePath.lastIndexOf('.')
    if (lastDot === -1) {
      return ''
    }
    return filePath.substring(lastDot).toLowerCase()
  }

  /**
   * 获取文件名（不含扩展名）
   */
  static getFileName(filePath: string): string {
    const lastSlash = filePath.lastIndexOf('/')
    const fileName = lastSlash === -1 ? filePath : filePath.substring(lastSlash + 1)
    const lastDot = fileName.lastIndexOf('.')
    return lastDot === -1 ? fileName : fileName.substring(0, lastDot)
  }

  /**
   * 获取文件名（含扩展名）
   */
  static getFileNameWithExt(filePath: string): string {
    const lastSlash = filePath.lastIndexOf('/')
    return lastSlash === -1 ? filePath : filePath.substring(lastSlash + 1)
  }

  /**
   * 获取目录路径
   */
  static getDirectory(filePath: string): string {
    const lastSlash = filePath.lastIndexOf('/')
    return lastSlash === -1 ? '' : filePath.substring(0, lastSlash)
  }

  /**
   * 格式化文件大小
   */
  static formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
    }
  }

  /**
   * 判断是否是音频文件
   */
  static isAudioFile(filePath: string): boolean {
    const audioExtensions = ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a', '.wma']
    const ext = FileUtils.getExtension(filePath)
    return audioExtensions.includes(ext)
  }
}
