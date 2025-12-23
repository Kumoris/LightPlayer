import { Song } from '../model/Song'

/**
 * 歌曲列表数据源
 * 用于 LazyForEach 实现懒加载
 */
export class SongDataSource implements IDataSource {
  private songs: Song[] = []
  private listeners: DataChangeListener[] = []

  constructor(songs: Song[] = []) {
    this.songs = songs
  }

  /**
   * 设置数据
   */
  setData(songs: Song[]): void {
    this.songs = songs
    this.notifyDataReload()
  }

  /**
   * 获取所有数据
   */
  getAllData(): Song[] {
    return this.songs
  }

  /**
   * 添加数据
   */
  addData(song: Song): void {
    this.songs.push(song)
    this.notifyDataAdd(this.songs.length - 1)
  }

  /**
   * 批量添加数据
   */
  addDataBatch(songs: Song[]): void {
    const startIndex = this.songs.length
    this.songs = this.songs.concat(songs)
    // 通知变化
    for (let i = 0; i < songs.length; i++) {
      this.notifyDataAdd(startIndex + i)
    }
  }

  /**
   * 删除数据
   */
  deleteData(index: number): void {
    if (index >= 0 && index < this.songs.length) {
      this.songs.splice(index, 1)
      this.notifyDataDelete(index)
    }
  }

  /**
   * 更新数据
   */
  updateData(index: number, song: Song): void {
    if (index >= 0 && index < this.songs.length) {
      this.songs[index] = song
      this.notifyDataChange(index)
    }
  }

  /**
   * 清空数据
   */
  clearData(): void {
    this.songs = []
    this.notifyDataReload()
  }

  // ========== IDataSource 接口实现 ==========

  totalCount(): number {
    return this.songs.length
  }

  getData(index: number): Song {
    return this.songs[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  // ========== 通知方法 ==========

  private notifyDataReload(): void {
    for (const listener of this.listeners) {
      listener.onDataReloaded()
    }
  }

  private notifyDataAdd(index: number): void {
    for (const listener of this.listeners) {
      listener.onDataAdd(index)
    }
  }

  private notifyDataChange(index: number): void {
    for (const listener of this.listeners) {
      listener.onDataChange(index)
    }
  }

  private notifyDataDelete(index: number): void {
    for (const listener of this.listeners) {
      listener.onDataDelete(index)
    }
  }

  private notifyDataMove(from: number, to: number): void {
    for (const listener of this.listeners) {
      listener.onDataMove(from, to)
    }
  }
}

/**
 * 通用列表数据源
 * 用于播放列表等其他列表
 */
export class GenericDataSource<T> implements IDataSource {
  private items: T[] = []
  private listeners: DataChangeListener[] = []

  constructor(items: T[] = []) {
    this.items = items
  }

  setData(items: T[]): void {
    this.items = items
    this.notifyDataReload()
  }

  getAllData(): T[] {
    return this.items
  }

  totalCount(): number {
    return this.items.length
  }

  getData(index: number): T {
    return this.items[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  private notifyDataReload(): void {
    for (const listener of this.listeners) {
      listener.onDataReloaded()
    }
  }
}
