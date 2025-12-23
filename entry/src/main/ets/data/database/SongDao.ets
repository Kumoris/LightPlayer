import { relationalStore } from '@kit.ArkData'
import { Song, createSong } from '../../model/Song'
import { DatabaseHelper } from './DatabaseHelper'

/**
 * 歌曲数据访问对象
 * 负责歌曲表的CRUD操作
 */
export class SongDao {
  private static instance: SongDao | null = null
  private dbHelper: DatabaseHelper

  private constructor() {
    this.dbHelper = DatabaseHelper.getInstance()
  }

  static getInstance(): SongDao {
    if (!SongDao.instance) {
      SongDao.instance = new SongDao()
    }
    return SongDao.instance
  }

  /**
   * 插入歌曲
   */
  async insert(song: Song): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return -1
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'duration': song.duration,
      'path': song.path,
      'album_art': song.albumArt,
      'date_added': song.dateAdded,
      'size': song.size,
      'mime_type': song.mimeType
    }

    try {
      return await rdbStore.insert('songs', valueBucket)
    } catch (error) {
      console.error('SongDao', `Insert song failed: ${JSON.stringify(error)}`)
      return -1
    }
  }

  /**
   * 批量插入歌曲
   */
  async insertBatch(songs: Song[]): Promise<number> {
    let insertCount = 0
    for (const song of songs) {
      try {
        const result = await this.insert(song)
        if (result > 0) {
          insertCount++
        }
      } catch (error) {
        console.warn('SongDao', `Insert song failed: ${song.path}`)
      }
    }
    return insertCount
  }

  /**
   * 查询所有歌曲
   */
  async queryAll(): Promise<Song[]> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return []
    }

    try {
      const predicates = new relationalStore.RdbPredicates('songs')
      predicates.orderByAsc('title')
      const resultSet = await rdbStore.query(predicates)
      return this.resultSetToSongs(resultSet)
    } catch (error) {
      console.error('SongDao', `Query all songs failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 根据ID查询歌曲
   */
  async queryById(id: number): Promise<Song | null> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return null
    }

    try {
      const predicates = new relationalStore.RdbPredicates('songs')
      predicates.equalTo('id', id)
      const resultSet = await rdbStore.query(predicates)
      const songs = this.resultSetToSongs(resultSet)
      return songs.length > 0 ? songs[0] : null
    } catch (error) {
      console.error('SongDao', `Query song by id failed: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 根据路径查询歌曲
   */
  async queryByPath(path: string): Promise<Song | null> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return null
    }

    try {
      const predicates = new relationalStore.RdbPredicates('songs')
      predicates.equalTo('path', path)
      const resultSet = await rdbStore.query(predicates)
      const songs = this.resultSetToSongs(resultSet)
      return songs.length > 0 ? songs[0] : null
    } catch (error) {
      console.error('SongDao', `Query song by path failed: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 搜索歌曲
   */
  async search(keyword: string): Promise<Song[]> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return []
    }

    try {
      const predicates = new relationalStore.RdbPredicates('songs')
      predicates.like('title', `%${keyword}%`)
        .or()
        .like('artist', `%${keyword}%`)
        .or()
        .like('album', `%${keyword}%`)
      const resultSet = await rdbStore.query(predicates)
      return this.resultSetToSongs(resultSet)
    } catch (error) {
      console.error('SongDao', `Search songs failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 删除歌曲
   */
  async delete(id: number): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return 0
    }

    try {
      const predicates = new relationalStore.RdbPredicates('songs')
      predicates.equalTo('id', id)
      return await rdbStore.delete(predicates)
    } catch (error) {
      console.error('SongDao', `Delete song failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 清空所有歌曲
   */
  async deleteAll(): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return 0
    }

    try {
      const predicates = new relationalStore.RdbPredicates('songs')
      return await rdbStore.delete(predicates)
    } catch (error) {
      console.error('SongDao', `Delete all songs failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 将ResultSet转换为Song数组
   */
  private resultSetToSongs(resultSet: relationalStore.ResultSet): Song[] {
    const songs: Song[] = []
    try {
      const idIndex = resultSet.getColumnIndex('id')
      const titleIndex = resultSet.getColumnIndex('title')
      const artistIndex = resultSet.getColumnIndex('artist')
      const albumIndex = resultSet.getColumnIndex('album')
      const durationIndex = resultSet.getColumnIndex('duration')
      const pathIndex = resultSet.getColumnIndex('path')
      const albumArtIndex = resultSet.getColumnIndex('album_art')
      const dateAddedIndex = resultSet.getColumnIndex('date_added')
      const sizeIndex = resultSet.getColumnIndex('size')
      const mimeTypeIndex = resultSet.getColumnIndex('mime_type')

      while (resultSet.goToNextRow()) {
        try {
          const song = createSong(
            resultSet.getLong(idIndex),
            resultSet.getString(titleIndex),
            resultSet.getString(artistIndex),
            resultSet.getString(albumIndex),
            resultSet.getLong(durationIndex),
            resultSet.getString(pathIndex),
            resultSet.getString(albumArtIndex),
            resultSet.getLong(dateAddedIndex),
            resultSet.getLong(sizeIndex),
            resultSet.getString(mimeTypeIndex)
          )
          songs.push(song)
        } catch (rowError) {
          console.error('SongDao', `Parse row failed: ${JSON.stringify(rowError)}`)
        }
      }
    } catch (error) {
      console.error('SongDao', `ResultSet to songs failed: ${JSON.stringify(error)}`)
    } finally {
      try {
        resultSet.close()
      } catch (closeError) {
        console.error('SongDao', `Close resultSet failed: ${JSON.stringify(closeError)}`)
      }
    }
    return songs
  }
}
