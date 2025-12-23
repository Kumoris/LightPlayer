import { fileIo } from '@kit.CoreFileKit'
import { picker } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { Song, createSong } from '../model/Song'
import { SongRepository } from '../data/repository/SongRepository'

/**
 * 支持的音频格式
 */
const SUPPORTED_AUDIO_EXTENSIONS: string[] = ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a']

/**
 * MIME类型映射
 */
class MimeTypeMap {
  private map: Map<string, string> = new Map()

  constructor() {
    this.map.set('mp3', 'audio/mpeg')
    this.map.set('flac', 'audio/flac')
    this.map.set('wav', 'audio/wav')
    this.map.set('aac', 'audio/aac')
    this.map.set('ogg', 'audio/ogg')
    this.map.set('m4a', 'audio/mp4')
  }

  get(ext: string): string {
    return this.map.get(ext) || 'audio/*'
  }
}

const mimeTypeMap = new MimeTypeMap()

/**
 * 扫描进度回调
 */
export interface ScanProgressCallback {
  onStart?: () => void
  onProgress?: (current: number, total: number, currentFile?: string) => void
  onSongFound?: (song: Song) => void
  onComplete?: (songs: Song[]) => void
  onError?: (error: string) => void
}

/**
 * 扫描状态
 */
export enum ScanStatus {
  IDLE = 'idle',
  SCANNING = 'scanning',
  COMPLETED = 'completed',
  ERROR = 'error'
}

/**
 * 音乐扫描服务
 * 负责扫描本地音乐文件
 * 使用文件选择器让用户选择音乐文件
 */
export class MusicScanService {
  private static instance: MusicScanService | null = null
  private songRepository: SongRepository
  private scanStatus: ScanStatus = ScanStatus.IDLE
  private context: common.UIAbilityContext | null = null

  private constructor() {
    this.songRepository = SongRepository.getInstance()
  }

  static getInstance(): MusicScanService {
    if (!MusicScanService.instance) {
      MusicScanService.instance = new MusicScanService()
    }
    return MusicScanService.instance
  }

  /**
   * 设置上下文
   */
  setContext(context: common.UIAbilityContext): void {
    this.context = context
  }

  /**
   * 获取扫描状态
   */
  getScanStatus(): ScanStatus {
    return this.scanStatus
  }

  /**
   * 是否正在扫描
   */
  isScanning(): boolean {
    return this.scanStatus === ScanStatus.SCANNING
  }

  /**
   * 扫描媒体库 - 直接打开文件选择器让用户选择音乐
   * 由于鸿蒙的安全限制，应用无法直接扫描系统目录
   * 需要用户通过文件选择器授权访问
   */
  async scanMediaLibrary(context: common.UIAbilityContext, callback?: ScanProgressCallback): Promise<Song[]> {
    if (this.scanStatus === ScanStatus.SCANNING) {
      console.warn('MusicScanService', 'Already scanning')
      callback?.onError?.('Already scanning')
      return []
    }

    // 直接使用文件选择器
    return await this.selectAudioFiles(context, callback)
  }

  /**
   * 使用文件选择器选择音频文件
   */
  async selectAudioFiles(context: common.UIAbilityContext, callback?: ScanProgressCallback): Promise<Song[]> {
    if (this.scanStatus === ScanStatus.SCANNING) {
      console.warn('MusicScanService', 'Already scanning')
      callback?.onError?.('Already scanning')
      return []
    }

    this.scanStatus = ScanStatus.SCANNING
    this.context = context
    callback?.onStart?.()
    console.info('MusicScanService', 'Opening file picker for audio files')

    const songs: Song[] = []

    try {
      // 创建文档选择器（支持选择多个音频文件）
      const documentPicker = new picker.DocumentViewPicker(context)

      // 配置选择选项
      const documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 100 // 最多选择100个文件
      documentSelectOptions.fileSuffixFilters = ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a']

      // 打开文件选择器
      const uris = await documentPicker.select(documentSelectOptions)

      console.info('MusicScanService', `Selected ${uris.length} audio files`)

      if (uris.length > 0) {
        // 先获取数据库中现有歌曲的最大ID
        const existingSongs = await this.songRepository.getAllSongs()
        let maxId = 0
        for (const s of existingSongs) {
          if (s.id > maxId) {
            maxId = s.id
          }
        }

        for (let i = 0; i < uris.length; i++) {
          const uri = uris[i]

          // 检查是否已存在
          const exists = existingSongs.some(s => s.path === uri)
          if (exists) {
            console.info('MusicScanService', `Song already exists: ${uri}`)
            callback?.onProgress?.(i + 1, uris.length, uri)
            continue
          }

          const song = await this.parseAudioFileFromUri(uri, maxId + songs.length + 1)
          if (song) {
            songs.push(song)
            callback?.onSongFound?.(song)
          }
          callback?.onProgress?.(i + 1, uris.length, uri)
        }
      }

      // 保存到数据库
      if (songs.length > 0) {
        await this.songRepository.saveSongs(songs)
        console.info('MusicScanService', `Saved ${songs.length} songs to database`)
      }

      this.scanStatus = ScanStatus.COMPLETED

      // 重新加载所有歌曲返回
      const allSongs = await this.songRepository.getAllSongs()
      callback?.onComplete?.(allSongs)
      console.info('MusicScanService', `Selection completed, added ${songs.length} new songs`)

    } catch (error) {
      console.error('MusicScanService', `Select audio files failed: ${JSON.stringify(error)}`)
      this.scanStatus = ScanStatus.ERROR
      callback?.onError?.(`选择文件失败: ${JSON.stringify(error)}`)
    }

    return songs
  }

  /**
   * 从 URI 解析音频文件
   */
  private async parseAudioFileFromUri(uri: string, id: number): Promise<Song | null> {
    try {
      // 从 URI 中提取文件名
      let fileName = 'Unknown'

      // 尝试从 URI 解析文件名
      if (uri.includes('/')) {
        const parts = uri.split('/')
        fileName = parts[parts.length - 1] || 'Unknown'
      }

      // 解码文件名
      try {
        fileName = decodeURIComponent(fileName)
      } catch (e) {
        // 解码失败则使用原始名称
      }

      const lastDotIndex = fileName.lastIndexOf('.')
      const nameWithoutExt = lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName

      // 尝试从文件名解析艺术家和标题
      let artist = '未知艺术家'
      let title = nameWithoutExt

      if (nameWithoutExt.includes(' - ')) {
        const parts = nameWithoutExt.split(' - ')
        artist = parts[0].trim()
        const remainingParts: string[] = []
        for (let i = 1; i < parts.length; i++) {
          remainingParts.push(parts[i])
        }
        title = remainingParts.join(' - ').trim()
      }

      // 尝试获取文件信息
      let fileSize = 0
      try {
        const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(file.fd)
        fileSize = stat.size
        fileIo.closeSync(file)
      } catch (e) {
        console.warn('MusicScanService', `Cannot get file size for: ${uri}`)
      }

      return createSong(
        id,
        title,
        artist,
        '未知专辑',
        0, // duration - 播放时获取
        uri,
        '',
        Date.now(),
        fileSize,
        this.getMimeType(fileName)
      )
    } catch (error) {
      console.error('MusicScanService', `Parse audio file from URI failed: ${uri}, error: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 获取MIME类型
   */
  private getMimeType(filePath: string): string {
    const lastDotIndex = filePath.lastIndexOf('.')
    if (lastDotIndex === -1) {
      return 'audio/*'
    }
    const ext = filePath.substring(lastDotIndex + 1).toLowerCase()
    return mimeTypeMap.get(ext)
  }

  /**
   * 从数据库加载歌曲
   */
  async loadSongsFromDatabase(): Promise<Song[]> {
    try {
      return await this.songRepository.getAllSongs()
    } catch (error) {
      console.error('MusicScanService', `Load songs from database failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 刷新歌曲库（重新扫描）
   */
  async refreshLibrary(context: common.UIAbilityContext, callback?: ScanProgressCallback): Promise<Song[]> {
    // 清空现有数据
    await this.songRepository.clearAllSongs()
    // 重新让用户选择
    return await this.selectAudioFiles(context, callback)
  }

  /**
   * 通过文件选择器添加音乐
   */
  async addMusicByPicker(context: common.UIAbilityContext, callback?: ScanProgressCallback): Promise<Song[]> {
    return await this.selectAudioFiles(context, callback)
  }
}
