import { relationalStore } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

/**
 * 数据库配置
 */
const DB_CONFIG: relationalStore.StoreConfig = {
  name: 'MusicPlayer.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

/**
 * 数据库帮助类
 * 负责数据库的创建、升级和基本操作
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null
  private rdbStore: relationalStore.RdbStore | null = null
  private context: Context | null = null
  private initialized: boolean = false

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  /**
   * 初始化数据库
   */
  async initialize(context: Context): Promise<boolean> {
    this.context = context
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, DB_CONFIG)
      await this.createTables()
      this.initialized = true
      return true
    } catch (error) {
      console.error('DatabaseHelper', `Initialize database failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized
  }

  /**
   * 创建数据表
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return
    }

    // 歌曲表
    const createSongTable = `
      CREATE TABLE IF NOT EXISTS songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration INTEGER DEFAULT 0,
        path TEXT NOT NULL UNIQUE,
        album_art TEXT,
        date_added INTEGER,
        size INTEGER DEFAULT 0,
        mime_type TEXT
      )
    `

    // 播放列表表
    const createPlaylistTable = `
      CREATE TABLE IF NOT EXISTS playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        cover_uri TEXT,
        create_time INTEGER,
        update_time INTEGER
      )
    `

    // 播放列表歌曲关联表
    const createPlaylistSongsTable = `
      CREATE TABLE IF NOT EXISTS playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    `

    // 播放历史表
    const createPlayHistoryTable = `
      CREATE TABLE IF NOT EXISTS play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        play_time INTEGER,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    `

    try {
      await this.rdbStore.executeSql(createSongTable)
      await this.rdbStore.executeSql(createPlaylistTable)
      await this.rdbStore.executeSql(createPlaylistSongsTable)
      await this.rdbStore.executeSql(createPlayHistoryTable)
    } catch (error) {
      console.error('DatabaseHelper', `Create tables failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取数据库实例
   */
  getRdbStore(): relationalStore.RdbStore | null {
    return this.rdbStore
  }

  /**
   * 关闭数据库
   */
  async close(): Promise<void> {
    if (this.rdbStore) {
      this.rdbStore = null
      this.initialized = false
    }
  }
}
