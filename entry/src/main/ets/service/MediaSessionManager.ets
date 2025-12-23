import { avSession } from '@kit.AVSessionKit'
import { image } from '@kit.ImageKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Song } from '../model/Song'
import { fileIo } from '@kit.CoreFileKit'

/**
 * 媒体会话事件监听器接口
 */
export interface MediaSessionEventListener {
  onPlay?: () => void
  onPause?: () => void
  onPlayNext?: () => void
  onPlayPrevious?: () => void
  onSeek?: (time: number) => void
}

/**
 * 媒体会话管理器
 * 负责管理 AVSession，实现通知栏播放控制
 */
export class MediaSessionManager {
  private static instance: MediaSessionManager | null = null
  private session: avSession.AVSession | null = null
  private context: Context | null = null
  private listener: MediaSessionEventListener | null = null
  private isActive: boolean = false

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): MediaSessionManager {
    if (!MediaSessionManager.instance) {
      MediaSessionManager.instance = new MediaSessionManager()
    }
    return MediaSessionManager.instance
  }

  /**
   * 初始化媒体会话
   * @param context 应用上下文
   */
  async initialize(context: Context): Promise<boolean> {
    this.context = context

    try {
      // 创建 AVSession
      this.session = await avSession.createAVSession(context, 'MusicPlayer', 'audio')
      console.info('MediaSessionManager', 'AVSession created successfully')

      // 设置支持的命令
      this.setupCommands()

      return true
    } catch (error) {
      const err = error as BusinessError
      console.error('MediaSessionManager', `Failed to create AVSession: ${err.code} - ${err.message}`)
      return false
    }
  }

  /**
   * 设置事件监听器
   */
  setEventListener(listener: MediaSessionEventListener): void {
    this.listener = listener
  }

  /**
   * 设置支持的控制命令
   */
  private setupCommands(): void {
    if (!this.session) {
      return
    }

    try {
      // 播放命令
      this.session.on('play', () => {
        console.info('MediaSessionManager', 'Received play command')
        if (this.listener?.onPlay) {
          this.listener.onPlay()
        }
      })
    } catch (e) {
      console.warn('MediaSessionManager', `Failed to register play command: ${e}`)
    }

    try {
      // 暂停命令
      this.session.on('pause', () => {
        console.info('MediaSessionManager', 'Received pause command')
        if (this.listener?.onPause) {
          this.listener.onPause()
        }
      })
    } catch (e) {
      console.warn('MediaSessionManager', `Failed to register pause command: ${e}`)
    }

    try {
      // 下一首命令
      this.session.on('playNext', () => {
        console.info('MediaSessionManager', 'Received playNext command')
        if (this.listener?.onPlayNext) {
          this.listener.onPlayNext()
        }
      })
    } catch (e) {
      console.warn('MediaSessionManager', `Failed to register playNext command: ${e}`)
    }

    try {
      // 上一首命令
      this.session.on('playPrevious', () => {
        console.info('MediaSessionManager', 'Received playPrevious command')
        if (this.listener?.onPlayPrevious) {
          this.listener.onPlayPrevious()
        }
      })
    } catch (e) {
      console.warn('MediaSessionManager', `Failed to register playPrevious command: ${e}`)
    }

    try {
      // 跳转命令
      this.session.on('seek', (time: number) => {
        console.info('MediaSessionManager', `Received seek command: ${time}`)
        if (this.listener?.onSeek) {
          this.listener.onSeek(time)
        }
      })
    } catch (e) {
      console.warn('MediaSessionManager', `Failed to register seek command: ${e}`)
    }

    console.info('MediaSessionManager', 'Commands setup completed')
  }

  /**
   * 激活会话
   */
  async activate(): Promise<boolean> {
    if (!this.session) {
      console.error('MediaSessionManager', 'Session not initialized')
      return false
    }

    if (this.isActive) {
      return true
    }

    try {
      await this.session.activate()
      this.isActive = true
      console.info('MediaSessionManager', 'Session activated')
      return true
    } catch (error) {
      const err = error as BusinessError
      console.error('MediaSessionManager', `Failed to activate session: ${err.code} - ${err.message}`)
      return false
    }
  }

  /**
   * 停用会话
   */
  async deactivate(): Promise<boolean> {
    if (!this.session || !this.isActive) {
      return true
    }

    try {
      await this.session.deactivate()
      this.isActive = false
      console.info('MediaSessionManager', 'Session deactivated')
      return true
    } catch (error) {
      const err = error as BusinessError
      console.error('MediaSessionManager', `Failed to deactivate session: ${err.code} - ${err.message}`)
      return false
    }
  }

  /**
   * 更新当前播放的媒体信息
   */
  async updateMetadata(song: Song): Promise<void> {
    if (!this.session) {
      return
    }

    try {
      const metadata: avSession.AVMetadata = {
        assetId: song.id.toString(),
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration
      }

      // 尝试加载专辑封面
      if (song.albumArt && song.albumArt.length > 0) {
        try {
          const pixelMap = await this.loadAlbumArt(song.albumArt)
          if (pixelMap) {
            metadata.mediaImage = pixelMap
          }
        } catch (e) {
          console.warn('MediaSessionManager', `Failed to load album art: ${e}`)
        }
      }

      await this.session.setAVMetadata(metadata)
      console.info('MediaSessionManager', `Metadata updated: ${song.title}`)
    } catch (error) {
      const err = error as BusinessError
      console.error('MediaSessionManager', `Failed to update metadata: ${err.code} - ${err.message}`)
    }
  }

  /**
   * 加载专辑封面图片
   */
  private async loadAlbumArt(uri: string): Promise<image.PixelMap | null> {
    try {
      // 如果是文件路径
      if (uri.startsWith('/') || uri.startsWith('file://')) {
        const path = uri.startsWith('file://') ? uri.substring(7) : uri
        const file = await fileIo.open(path, fileIo.OpenMode.READ_ONLY)
        const imageSource = image.createImageSource(file.fd)
        const pixelMap = await imageSource.createPixelMap()
        await fileIo.close(file)
        return pixelMap
      }
      return null
    } catch (e) {
      console.warn('MediaSessionManager', `Load album art failed: ${e}`)
      return null
    }
  }

  /**
   * 更新播放状态
   */
  async updatePlaybackState(isPlaying: boolean, position: number, duration: number): Promise<void> {
    if (!this.session) {
      return
    }

    try {
      const playbackState: avSession.AVPlaybackState = {
        state: isPlaying ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
        position: {
          elapsedTime: position,
          updateTime: Date.now()
        },
        duration: duration
      }

      await this.session.setAVPlaybackState(playbackState)
    } catch (error) {
      const err = error as BusinessError
      console.error('MediaSessionManager', `Failed to update playback state: ${err.code} - ${err.message}`)
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    if (this.session) {
      try {
        // 关闭所有监听
        this.session.off('play')
        this.session.off('pause')
        this.session.off('playNext')
        this.session.off('playPrevious')
        this.session.off('seek')

        await this.session.destroy()
        this.session = null
        this.isActive = false
        console.info('MediaSessionManager', 'Session destroyed')
      } catch (error) {
        const err = error as BusinessError
        console.error('MediaSessionManager', `Failed to destroy session: ${err.code} - ${err.message}`)
      }
    }
    this.listener = null
    this.context = null
  }
}
