import { relationalStore } from '@kit.ArkData'
import { Playlist, createPlaylist } from '../../model/Playlist'
import { DatabaseHelper } from './DatabaseHelper'

/**
 * 播放列表数据访问对象
 */
export class PlaylistDao {
  private static instance: PlaylistDao | null = null
  private dbHelper: DatabaseHelper

  private constructor() {
    this.dbHelper = DatabaseHelper.getInstance()
  }

  static getInstance(): PlaylistDao {
    if (!PlaylistDao.instance) {
      PlaylistDao.instance = new PlaylistDao()
    }
    return PlaylistDao.instance
  }

  /**
   * 创建播放列表
   */
  async create(playlist: Playlist): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return -1
    }

    const now = Date.now()
    const valueBucket: relationalStore.ValuesBucket = {
      'name': playlist.name,
      'description': playlist.description,
      'cover_uri': playlist.coverUri,
      'create_time': now,
      'update_time': now
    }

    try {
      return await rdbStore.insert('playlists', valueBucket)
    } catch (error) {
      console.error('PlaylistDao', `Create playlist failed: ${JSON.stringify(error)}`)
      return -1
    }
  }

  /**
   * 查询所有播放列表
   */
  async queryAll(): Promise<Playlist[]> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return []
    }

    try {
      const predicates = new relationalStore.RdbPredicates('playlists')
      predicates.orderByDesc('update_time')
      const resultSet = await rdbStore.query(predicates)
      const playlists = this.resultSetToPlaylists(resultSet)

      // 查询每个播放列表的歌曲ID
      for (const playlist of playlists) {
        playlist.songIds = await this.getPlaylistSongIds(playlist.id)
      }

      return playlists
    } catch (error) {
      console.error('PlaylistDao', `Query all playlists failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 根据ID查询播放列表
   */
  async queryById(id: number): Promise<Playlist | null> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return null
    }

    try {
      const predicates = new relationalStore.RdbPredicates('playlists')
      predicates.equalTo('id', id)
      const resultSet = await rdbStore.query(predicates)
      const playlists = this.resultSetToPlaylists(resultSet)

      if (playlists.length > 0) {
        playlists[0].songIds = await this.getPlaylistSongIds(id)
        return playlists[0]
      }
      return null
    } catch (error) {
      console.error('PlaylistDao', `Query playlist by id failed: ${JSON.stringify(error)}`)
      return null
    }
  }

  /**
   * 更新播放列表
   */
  async update(playlist: Playlist): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return 0
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'name': playlist.name,
      'description': playlist.description,
      'cover_uri': playlist.coverUri,
      'update_time': Date.now()
    }

    try {
      const predicates = new relationalStore.RdbPredicates('playlists')
      predicates.equalTo('id', playlist.id)
      return await rdbStore.update(valueBucket, predicates)
    } catch (error) {
      console.error('PlaylistDao', `Update playlist failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 删除播放列表
   */
  async delete(id: number): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return 0
    }

    try {
      // 先删除关联的歌曲
      const songPredicates = new relationalStore.RdbPredicates('playlist_songs')
      songPredicates.equalTo('playlist_id', id)
      await rdbStore.delete(songPredicates)

      // 再删除播放列表
      const predicates = new relationalStore.RdbPredicates('playlists')
      predicates.equalTo('id', id)
      return await rdbStore.delete(predicates)
    } catch (error) {
      console.error('PlaylistDao', `Delete playlist failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 添加歌曲到播放列表
   */
  async addSong(playlistId: number, songId: number): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return -1
    }

    try {
      // 获取当前最大排序值
      const songIds = await this.getPlaylistSongIds(playlistId)
      const sortOrder = songIds.length

      const valueBucket: relationalStore.ValuesBucket = {
        'playlist_id': playlistId,
        'song_id': songId,
        'sort_order': sortOrder
      }

      const result = await rdbStore.insert('playlist_songs', valueBucket)

      // 更新播放列表的更新时间
      await this.updatePlaylistTime(playlistId)

      return result
    } catch (error) {
      console.error('PlaylistDao', `Add song to playlist failed: ${JSON.stringify(error)}`)
      return -1
    }
  }

  /**
   * 从播放列表移除歌曲
   */
  async removeSong(playlistId: number, songId: number): Promise<number> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return 0
    }

    try {
      const predicates = new relationalStore.RdbPredicates('playlist_songs')
      predicates.equalTo('playlist_id', playlistId)
        .and()
        .equalTo('song_id', songId)

      const result = await rdbStore.delete(predicates)
      await this.updatePlaylistTime(playlistId)
      return result
    } catch (error) {
      console.error('PlaylistDao', `Remove song from playlist failed: ${JSON.stringify(error)}`)
      return 0
    }
  }

  /**
   * 获取播放列表的歌曲ID列表
   */
  private async getPlaylistSongIds(playlistId: number): Promise<number[]> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return []
    }

    try {
      const predicates = new relationalStore.RdbPredicates('playlist_songs')
      predicates.equalTo('playlist_id', playlistId)
      predicates.orderByAsc('sort_order')

      const resultSet = await rdbStore.query(predicates)
      const songIds: number[] = []

      try {
        const songIdIndex = resultSet.getColumnIndex('song_id')
        while (resultSet.goToNextRow()) {
          try {
            songIds.push(resultSet.getLong(songIdIndex))
          } catch (rowError) {
            console.error('PlaylistDao', `Parse song id failed: ${JSON.stringify(rowError)}`)
          }
        }
      } finally {
        try {
          resultSet.close()
        } catch (closeError) {
          console.error('PlaylistDao', `Close resultSet failed: ${JSON.stringify(closeError)}`)
        }
      }

      return songIds
    } catch (error) {
      console.error('PlaylistDao', `Get playlist song ids failed: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 更新播放列表时间
   */
  private async updatePlaylistTime(playlistId: number): Promise<void> {
    const rdbStore = this.dbHelper.getRdbStore()
    if (!rdbStore) {
      return
    }

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'update_time': Date.now()
      }

      const predicates = new relationalStore.RdbPredicates('playlists')
      predicates.equalTo('id', playlistId)

      await rdbStore.update(valueBucket, predicates)
    } catch (error) {
      console.error('PlaylistDao', `Update playlist time failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 将ResultSet转换为Playlist数组
   */
  private resultSetToPlaylists(resultSet: relationalStore.ResultSet): Playlist[] {
    const playlists: Playlist[] = []
    try {
      const idIndex = resultSet.getColumnIndex('id')
      const nameIndex = resultSet.getColumnIndex('name')
      const descriptionIndex = resultSet.getColumnIndex('description')
      const coverUriIndex = resultSet.getColumnIndex('cover_uri')
      const createTimeIndex = resultSet.getColumnIndex('create_time')
      const updateTimeIndex = resultSet.getColumnIndex('update_time')

      while (resultSet.goToNextRow()) {
        try {
          const playlist = createPlaylist(
            resultSet.getLong(idIndex),
            resultSet.getString(nameIndex),
            resultSet.getString(descriptionIndex),
            resultSet.getString(coverUriIndex),
            [],
            resultSet.getLong(createTimeIndex),
            resultSet.getLong(updateTimeIndex)
          )
          playlists.push(playlist)
        } catch (rowError) {
          console.error('PlaylistDao', `Parse playlist row failed: ${JSON.stringify(rowError)}`)
        }
      }
    } catch (error) {
      console.error('PlaylistDao', `ResultSet to playlists failed: ${JSON.stringify(error)}`)
    } finally {
      try {
        resultSet.close()
      } catch (closeError) {
        console.error('PlaylistDao', `Close resultSet failed: ${JSON.stringify(closeError)}`)
      }
    }
    return playlists
  }
}
