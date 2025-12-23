import { Song, createSong } from '../model/Song'
import { PlayMode } from '../model/PlayState'

/**
 * Song 数据传输对象接口
 * 用于 JSON 序列化/反序列化
 */
interface SongData {
  id: number
  title: string
  artist: string
  album: string
  duration: number
  path: string
  albumArt: string
  dateAdded: number
  size: number
  mimeType: string
}

/**
 * 全局播放状态 Key 定义
 * 用于 AppStorage 的键名
 */
export class PlayStateKeys {
  // 当前播放的歌曲（JSON字符串形式存储）
  static readonly CURRENT_SONG: string = 'currentSong'
  // 是否正在播放
  static readonly IS_PLAYING: string = 'isPlaying'
  // 是否正在加载（准备播放）
  static readonly IS_LOADING: string = 'isLoading'
  // 当前播放位置（毫秒）
  static readonly CURRENT_POSITION: string = 'currentPosition'
  // 当前歌曲总时长（毫秒）- 来自实际播放器，比歌曲元数据更准确
  static readonly CURRENT_DURATION: string = 'currentDuration'
  // 播放模式
  static readonly PLAY_MODE: string = 'playMode'
  // 歌曲列表（JSON字符串形式存储）
  static readonly SONG_LIST: string = 'songList'
  // 当前播放索引
  static readonly CURRENT_INDEX: string = 'currentIndex'
}

/**
 * 将 Song 对象转换为 SongData
 */
function songToData(song: Song): SongData {
  const data: SongData = {
    id: song.id,
    title: song.title,
    artist: song.artist,
    album: song.album,
    duration: song.duration,
    path: song.path,
    albumArt: song.albumArt,
    dateAdded: song.dateAdded,
    size: song.size,
    mimeType: song.mimeType
  }
  return data
}

/**
 * 将 SongData 转换为 Song 对象
 */
function dataToSong(data: SongData): Song {
  return createSong(
    data.id,
    data.title,
    data.artist,
    data.album,
    data.duration,
    data.path,
    data.albumArt,
    data.dateAdded,
    data.size,
    data.mimeType
  )
}

/**
 * 全局播放状态管理器
 * 负责初始化 AppStorage 并提供状态管理方法
 */
export class GlobalPlayState {
  private static instance: GlobalPlayState | null = null

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): GlobalPlayState {
    if (!GlobalPlayState.instance) {
      GlobalPlayState.instance = new GlobalPlayState()
    }
    return GlobalPlayState.instance
  }

  /**
   * 初始化全局播放状态
   * 应在 EntryAbility 的 onCreate 中调用
   */
  initializeStorage(): void {
    // 初始化当前歌曲（使用空 Song 的 JSON）
    if (!AppStorage.has(PlayStateKeys.CURRENT_SONG)) {
      AppStorage.setOrCreate<string>(PlayStateKeys.CURRENT_SONG, '')
    }

    // 初始化播放状态
    if (!AppStorage.has(PlayStateKeys.IS_PLAYING)) {
      AppStorage.setOrCreate<boolean>(PlayStateKeys.IS_PLAYING, false)
    }

    // 初始化加载状态
    if (!AppStorage.has(PlayStateKeys.IS_LOADING)) {
      AppStorage.setOrCreate<boolean>(PlayStateKeys.IS_LOADING, false)
    }

    // 初始化当前播放位置
    if (!AppStorage.has(PlayStateKeys.CURRENT_POSITION)) {
      AppStorage.setOrCreate<number>(PlayStateKeys.CURRENT_POSITION, 0)
    }

    // 初始化当前歌曲时长
    if (!AppStorage.has(PlayStateKeys.CURRENT_DURATION)) {
      AppStorage.setOrCreate<number>(PlayStateKeys.CURRENT_DURATION, 0)
    }

    // 初始化播放模式
    if (!AppStorage.has(PlayStateKeys.PLAY_MODE)) {
      AppStorage.setOrCreate<number>(PlayStateKeys.PLAY_MODE, PlayMode.SEQUENCE)
    }

    // 初始化歌曲列表
    if (!AppStorage.has(PlayStateKeys.SONG_LIST)) {
      AppStorage.setOrCreate<string>(PlayStateKeys.SONG_LIST, '[]')
    }

    // 初始化当前播放索引
    if (!AppStorage.has(PlayStateKeys.CURRENT_INDEX)) {
      AppStorage.setOrCreate<number>(PlayStateKeys.CURRENT_INDEX, -1)
    }

    console.info('GlobalPlayState', 'Storage initialized successfully')
  }

  /**
   * 设置当前播放歌曲
   */
  setCurrentSong(song: Song | null): void {
    if (song) {
      const songData: SongData = songToData(song)
      const songJson = JSON.stringify(songData)
      AppStorage.set<string>(PlayStateKeys.CURRENT_SONG, songJson)
      console.info('GlobalPlayState', `Set current song: ${song.title}`)
    } else {
      AppStorage.set<string>(PlayStateKeys.CURRENT_SONG, '')
    }
  }

  /**
   * 获取当前播放歌曲
   */
  getCurrentSong(): Song | null {
    const songJson = AppStorage.get<string>(PlayStateKeys.CURRENT_SONG)
    if (songJson && songJson.length > 0) {
      try {
        const data: SongData = JSON.parse(songJson) as SongData
        return dataToSong(data)
      } catch (e) {
        console.error('GlobalPlayState', `Parse song failed: ${e}`)
        return null
      }
    }
    return null
  }

  /**
   * 设置播放状态
   */
  setIsPlaying(isPlaying: boolean): void {
    AppStorage.set<boolean>(PlayStateKeys.IS_PLAYING, isPlaying)
    console.info('GlobalPlayState', `Set isPlaying: ${isPlaying}`)
  }

  /**
   * 设置加载状态
   */
  setIsLoading(isLoading: boolean): void {
    AppStorage.set<boolean>(PlayStateKeys.IS_LOADING, isLoading)
  }

  /**
   * 设置当前播放位置
   */
  setCurrentPosition(position: number): void {
    AppStorage.set<number>(PlayStateKeys.CURRENT_POSITION, position)
  }

  /**
   * 设置当前歌曲总时长（来自实际播放器）
   */
  setCurrentDuration(duration: number): void {
    AppStorage.set<number>(PlayStateKeys.CURRENT_DURATION, duration)
  }

  /**
   * 设置播放模式
   */
  setPlayMode(mode: PlayMode): void {
    AppStorage.set<number>(PlayStateKeys.PLAY_MODE, mode)
    console.info('GlobalPlayState', `Set playMode: ${mode}`)
  }

  /**
   * 设置歌曲列表
   */
  setSongList(songs: Song[]): void {
    const songDataList: SongData[] = []
    for (const song of songs) {
      songDataList.push(songToData(song))
    }
    const songsJson = JSON.stringify(songDataList)
    AppStorage.set<string>(PlayStateKeys.SONG_LIST, songsJson)
  }

  /**
   * 获取歌曲列表
   */
  getSongList(): Song[] {
    const songsJson = AppStorage.get<string>(PlayStateKeys.SONG_LIST)
    if (songsJson && songsJson.length > 0) {
      try {
        const dataList: SongData[] = JSON.parse(songsJson) as SongData[]
        const result: Song[] = []
        for (const data of dataList) {
          result.push(dataToSong(data))
        }
        return result
      } catch (e) {
        console.error('GlobalPlayState', `Parse song list failed: ${e}`)
        return []
      }
    }
    return []
  }

  /**
   * 设置当前播放索引
   */
  setCurrentIndex(index: number): void {
    AppStorage.set<number>(PlayStateKeys.CURRENT_INDEX, index)
  }

  /**
   * 播放指定歌曲
   */
  playSong(song: Song, index: number): void {
    this.setCurrentSong(song)
    this.setCurrentIndex(index)
    this.setIsPlaying(true)
    this.setCurrentPosition(0)
    console.info('GlobalPlayState', `Play song: ${song.title} at index ${index}`)
  }

  /**
   * 切换播放/暂停
   */
  togglePlayPause(): void {
    const isPlaying = AppStorage.get<boolean>(PlayStateKeys.IS_PLAYING) ?? false
    this.setIsPlaying(!isPlaying)
  }

  /**
   * 播放下一首
   */
  playNext(): void {
    const songList = this.getSongList()
    if (songList.length === 0) {
      return
    }

    const currentIndex = AppStorage.get<number>(PlayStateKeys.CURRENT_INDEX) ?? -1
    const playMode = AppStorage.get<number>(PlayStateKeys.PLAY_MODE) ?? PlayMode.SEQUENCE
    let nextIndex: number

    switch (playMode) {
      case PlayMode.SHUFFLE:
        nextIndex = Math.floor(Math.random() * songList.length)
        break
      case PlayMode.SINGLE:
        nextIndex = currentIndex
        break
      default:
        nextIndex = (currentIndex + 1) % songList.length
    }

    const nextSong = songList[nextIndex]
    if (nextSong) {
      this.playSong(nextSong, nextIndex)
    }
  }

  /**
   * 播放上一首
   */
  playPrevious(): void {
    const songList = this.getSongList()
    if (songList.length === 0) {
      return
    }

    const currentIndex = AppStorage.get<number>(PlayStateKeys.CURRENT_INDEX) ?? 0
    const playMode = AppStorage.get<number>(PlayStateKeys.PLAY_MODE) ?? PlayMode.SEQUENCE
    let prevIndex: number

    switch (playMode) {
      case PlayMode.SHUFFLE:
        prevIndex = Math.floor(Math.random() * songList.length)
        break
      case PlayMode.SINGLE:
        prevIndex = currentIndex
        break
      default:
        prevIndex = currentIndex > 0 ? currentIndex - 1 : songList.length - 1
    }

    const prevSong = songList[prevIndex]
    if (prevSong) {
      this.playSong(prevSong, prevIndex)
    }
  }

  /**
   * 切换播放模式
   */
  togglePlayMode(): PlayMode {
    const modes: PlayMode[] = [PlayMode.SEQUENCE, PlayMode.LOOP, PlayMode.SINGLE, PlayMode.SHUFFLE]
    const currentMode = AppStorage.get<number>(PlayStateKeys.PLAY_MODE) ?? PlayMode.SEQUENCE
    const currentModeIndex = modes.indexOf(currentMode)
    const nextMode = modes[(currentModeIndex + 1) % modes.length]
    this.setPlayMode(nextMode)
    return nextMode
  }
}

/**
 * 将 Song JSON 字符串解析为 Song 对象的工具函数
 */
export function parseSongFromJson(songJson: string): Song | null {
  if (!songJson || songJson.length === 0) {
    return null
  }
  try {
    const data: SongData = JSON.parse(songJson) as SongData
    return dataToSong(data)
  } catch (e) {
    console.error('parseSongFromJson', `Parse failed: ${e}`)
    return null
  }
}
