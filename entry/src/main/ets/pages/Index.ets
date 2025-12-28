import { router, promptAction } from '@kit.ArkUI'
import { PlayMode } from '../model/PlayState'
import { common } from '@kit.AbilityKit'
import { Song } from '../model/Song'
import { Playlist } from '../model/Playlist'
import { MusicItem } from '../components/MusicItem'
import { MiniPlayer } from '../components/MiniPlayer'
import { PlayQueuePanel } from '../components/PlayQueuePanel'
import { PlayerDetailPanel } from '../components/PlayerDetailPanel'
import { MockData } from '../common/MockData'
import { GlobalPlayState, PlayStateKeys, parseSongFromJson } from '../common/GlobalPlayState'
import { PlayController } from '../common/PlayController'
import { PermissionManager } from '../common/PermissionManager'
import { MusicScanService, ScanProgressCallback, ScanStatus } from '../service/MusicScanService'
import { FavoriteService } from '../service/FavoriteService'
import { SongDataSource } from '../common/LazyDataSource'
import { SongRepository } from '../data/repository/SongRepository'

/**
 * 排序类型枚举
 */
enum SortType {
  TITLE = 0,      // 按文件名
  DATE_ADDED = 1, // 按添加时间
  DURATION = 2,   // 按时长
  ARTIST = 3      // 按艺术家
}

/**
 * 排序顺序枚举
 */
enum SortOrder {
  ASC = 0,   // 正序
  DESC = 1   // 倒序
}

/**
 * 主页 - 歌曲列表
 */
@Entry
@Component
struct Index {
  @State private currentTabIndex: number = 0
  @State private songs: Song[] = []
  @State private favoriteSongs: Song[] = []
  @State private playlists: Playlist[] = []
  @State private isPageLoading: boolean = true
  @State private isScanningMusic: boolean = false
  @State private scanProgress: number = 0
  @State private scanTotal: number = 0
  @State private scanStatusText: string = ''
  @State private permissionGranted: boolean = false
  @State private showPermissionDialog: boolean = false

  // 播放详情面板展开状态
  @State private isPlayerDetailExpanded: boolean = false

  // 排序相关状态
  @State private sortType: SortType = SortType.TITLE
  @State private sortOrder: SortOrder = SortOrder.ASC
  @State private showSortMenu: boolean = false

  // 批量操作相关状态
  @State private isSelectMode: boolean = false
  @State private selectedSongIds: Set<number> = new Set()

  // 使用 @StorageLink 连接全局播放状态
  @StorageLink(PlayStateKeys.CURRENT_SONG) currentSongJson: string = ''
  @StorageLink(PlayStateKeys.IS_PLAYING) isPlaying: boolean = false
  @StorageLink(PlayStateKeys.IS_LOADING) isLoading: boolean = false
  @StorageLink(PlayStateKeys.PLAY_MODE) playMode: number = 0
  @StorageLink(PlayStateKeys.CURRENT_POSITION) currentPosition: number = 0
  @StorageLink(PlayStateKeys.CURRENT_DURATION) currentDuration: number = 0
  @StorageLink(PlayStateKeys.CURRENT_INDEX) @Watch('onCurrentIndexChange') currentIndex: number = -1

  // 播放控制器
  private playController: PlayController = PlayController.getInstance()
  private permissionManager: PermissionManager = PermissionManager.getInstance()
  private musicScanService: MusicScanService = MusicScanService.getInstance()
  private songRepository: SongRepository = SongRepository.getInstance()
  private favoriteService: FavoriteService = FavoriteService.getInstance()
  private context: common.UIAbilityContext | null = null

  // 列表滚动控制器
  private listScroller: Scroller = new Scroller()

  // LazyForEach 数据源
  private songDataSource: SongDataSource = new SongDataSource()

  // 播放列表弹窗控制器
  private playQueueDialogController: CustomDialogController = new CustomDialogController({
    builder: PlayQueuePanel(),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    offset: { dx: 0, dy: 0 }
  })

  aboutToAppear(): void {
    console.info('Index', 'aboutToAppear - Initializing')
    // 获取上下文 - 使用 getContext 并进行类型转换
    const ctx = getContext(this)
    if (ctx) {
      this.context = ctx as common.UIAbilityContext
    }

    // 加载模拟播放列表
    this.playlists = MockData.getMockPlaylists()

    // 初始化音乐库
    this.initializeMusicLibrary()
  }

  /**
   * 监听当前播放索引变化，自动滚动列表
   */
  onCurrentIndexChange(): void {
    if (this.currentIndex >= 0 && this.currentTabIndex === 0 && this.songs.length > 0) {
      // 延迟执行，确保列表已渲染
      setTimeout(() => {
        this.scrollToCurrentSong()
      }, 100)
    }
  }

  /**
   * 滚动到当前播放的歌曲
   */
  private scrollToCurrentSong(): void {
    if (this.currentIndex >= 0 && this.currentIndex < this.songs.length) {
      this.listScroller.scrollToIndex(this.currentIndex, true, ScrollAlign.CENTER)
      console.info('Index', `Scrolled to current song at index: ${this.currentIndex}`)
    }
  }

  /**
   * 初始化音乐库
   */
  private async initializeMusicLibrary(): Promise<void> {
    this.isPageLoading = true
    this.scanStatusText = '正在初始化...'

    try {
      // 先尝试从数据库加载
      const cachedSongs = await this.musicScanService.loadSongsFromDatabase()

      if (cachedSongs.length > 0) {
        console.info('Index', `Loaded ${cachedSongs.length} songs from database`)
        this.songs = cachedSongs
        this.updateGlobalState()
        this.isPageLoading = false
        this.scanStatusText = ''
      } else {
        // 没有缓存，检查权限并扫描
        await this.checkAndRequestPermission()
      }
    } catch (error) {
      console.error('Index', `Initialize music library failed: ${JSON.stringify(error)}`)
      // 使用模拟数据作为后备
      this.loadMockData()
    }
  }

  /**
   * 检查并请求权限
   */
  private async checkAndRequestPermission(): Promise<void> {
    if (!this.context) {
      this.loadMockData()
      return
    }

    this.scanStatusText = '正在检查权限...'

    try {
      // 检查权限
      const hasPermission = await this.permissionManager.checkMediaReadPermission()

      if (hasPermission) {
        console.info('Index', 'Permission already granted')
        this.permissionGranted = true
        await this.startScanMusic()
      } else {
        // 请求权限
        console.info('Index', 'Requesting permission')
        const result = await this.permissionManager.requestMusicPlayerPermissions(this.context)

        if (result.granted) {
          console.info('Index', 'Permission granted')
          this.permissionGranted = true
          await this.startScanMusic()
        } else {
          console.warn('Index', 'Permission denied')
          this.permissionGranted = false
          this.showPermissionDialog = true
          // 使用模拟数据
          this.loadMockData()
        }
      }
    } catch (error) {
      console.error('Index', `Check permission failed: ${JSON.stringify(error)}`)
      this.loadMockData()
    }
  }

  /**
   * 开始扫描音乐
   */
  private async startScanMusic(): Promise<void> {
    if (!this.context) {
      this.loadMockData()
      return
    }

    this.isScanningMusic = true
    this.scanProgress = 0
    this.scanTotal = 0
    this.scanStatusText = '正在扫描音乐...'

    const callback: ScanProgressCallback = {
      onStart: () => {
        console.info('Index', 'Scan started')
        this.scanStatusText = '正在扫描音乐...'
      },
      onProgress: (current: number, total: number, currentFile?: string) => {
        this.scanProgress = current
        this.scanTotal = total
        if (total > 0) {
          const percent = Math.round((current / total) * 100)
          this.scanStatusText = `扫描中 ${percent}% (${current}/${total})`
        }
      },
      onSongFound: (song: Song) => {
        console.info('Index', `Found song: ${song.title}`)
      },
      onComplete: (songs: Song[]) => {
        console.info('Index', `Scan completed, found ${songs.length} songs`)
        this.songs = songs
        this.isScanningMusic = false
        this.isPageLoading = false
        this.scanStatusText = ''
        this.updateGlobalState()
      },
      onError: (error: string) => {
        console.error('Index', `Scan error: ${error}`)
        this.isScanningMusic = false
        this.isPageLoading = false
        this.scanStatusText = ''
        // 使用模拟数据作为后备
        if (this.songs.length === 0) {
          this.loadMockData()
        }
      }
    }

    try {
      await this.musicScanService.scanMediaLibrary(this.context, callback)
    } catch (error) {
      console.error('Index', `Scan failed: ${JSON.stringify(error)}`)
      this.loadMockData()
    }
  }

  /**
   * 加载模拟数据
   */
  private loadMockData(): void {
    console.info('Index', 'Loading mock data')
    this.songs = MockData.getMockSongs()
    this.isPageLoading = false
    this.isScanningMusic = false
    this.scanStatusText = ''
    this.updateGlobalState()
  }

  /**
   * 加载收藏歌曲列表
   */
  private async loadFavoriteSongs(): Promise<void> {
    try {
      this.favoriteSongs = await this.favoriteService.getFavoriteSongs()
      console.info('Index', `Loaded ${this.favoriteSongs.length} favorite songs`)
    } catch (error) {
      console.error('Index', `Load favorite songs failed: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 更新全局状态
   */
  private updateGlobalState(): void {
    // 将歌曲列表存入全局状态
    GlobalPlayState.getInstance().setSongList(this.songs)

    // 更新 LazyForEach 数据源
    this.songDataSource.setData(this.songs)

    // 如果没有当前歌曲，默认选中第一首（但不自动播放）
    if (!this.currentSongJson && this.songs.length > 0) {
      GlobalPlayState.getInstance().setCurrentSong(this.songs[0])
      GlobalPlayState.getInstance().setCurrentIndex(0)
      console.info('Index', `Default song set: ${this.songs[0].title}`)
    }
  }

  // ========== 排序功能 ==========

  /**
   * 获取排序类型名称
   */
  private getSortTypeName(): string {
    switch (this.sortType) {
      case SortType.TITLE: return '文件名'
      case SortType.DATE_ADDED: return '添加时间'
      case SortType.DURATION: return '时长'
      case SortType.ARTIST: return '艺术家'
      default: return '文件名'
    }
  }

  /**
   * 对歌曲列表进行排序
   */
  private sortSongs(): void {
    const sortedSongs = [...this.songs]

    sortedSongs.sort((a: Song, b: Song) => {
      let compareResult = 0

      switch (this.sortType) {
        case SortType.TITLE:
          compareResult = a.title.localeCompare(b.title)
          break
        case SortType.DATE_ADDED:
          compareResult = a.dateAdded - b.dateAdded
          break
        case SortType.DURATION:
          compareResult = a.duration - b.duration
          break
        case SortType.ARTIST:
          compareResult = a.artist.localeCompare(b.artist)
          break
      }

      return this.sortOrder === SortOrder.ASC ? compareResult : -compareResult
    })

    this.songs = sortedSongs
    this.updateGlobalState()
    console.info('Index', `Sorted by ${this.getSortTypeName()}, order: ${this.sortOrder === SortOrder.ASC ? '正序' : '倒序'}`)
  }

  /**
   * 设置排序类型
   */
  private setSortType(type: SortType): void {
    if (this.sortType === type) {
      // 如果点击同一个排序类型，切换排序顺序
      this.sortOrder = this.sortOrder === SortOrder.ASC ? SortOrder.DESC : SortOrder.ASC
    } else {
      this.sortType = type
      this.sortOrder = SortOrder.ASC
    }
    this.sortSongs()
    this.showSortMenu = false
  }

  // ========== 批量操作功能 ==========

  /**
   * 进入/退出多选模式
   */
  private toggleSelectMode(): void {
    this.isSelectMode = !this.isSelectMode
    if (!this.isSelectMode) {
      this.selectedSongIds.clear()
    }
    console.info('Index', `Select mode: ${this.isSelectMode}`)
  }

  /**
   * 处理歌曲选中状态变化
   */
  private handleSelectChange(song: Song, index: number, selected: boolean): void {
    if (selected) {
      this.selectedSongIds.add(song.id)
    } else {
      this.selectedSongIds.delete(song.id)
    }
    // 触发 UI 更新
    this.selectedSongIds = new Set(this.selectedSongIds)
    console.info('Index', `Selected songs: ${this.selectedSongIds.size}`)
  }

  /**
   * 全选/取消全选
   */
  private toggleSelectAll(): void {
    if (this.selectedSongIds.size === this.songs.length) {
      // 取消全选
      this.selectedSongIds.clear()
    } else {
      // 全选
      this.selectedSongIds.clear()
      for (const song of this.songs) {
        this.selectedSongIds.add(song.id)
      }
    }
    this.selectedSongIds = new Set(this.selectedSongIds)
  }

  /**
   * 批量删除选中的歌曲
   */
  private async deleteSelectedSongs(): Promise<void> {
    if (this.selectedSongIds.size === 0) {
      return
    }

    console.info('Index', `Deleting ${this.selectedSongIds.size} songs`)

    // 从数据库删除
    for (const songId of this.selectedSongIds) {
      await this.songRepository.deleteSong(songId)
    }

    // 从列表中移除
    this.songs = this.songs.filter((song: Song) => !this.selectedSongIds.has(song.id))
    this.updateGlobalState()

    // 清除选中状态并退出多选模式
    this.selectedSongIds.clear()
    this.isSelectMode = false

    console.info('Index', `Deleted successfully, remaining: ${this.songs.length} songs`)
  }

  /**
   * 将选中的歌曲添加到播放队列
   */
  private addSelectedToQueue(): void {
    if (this.selectedSongIds.size === 0) {
      return
    }

    const selectedSongs = this.songs.filter((song: Song) => this.selectedSongIds.has(song.id))
    // TODO: 实现添加到播放队列的逻辑
    console.info('Index', `Adding ${selectedSongs.length} songs to queue`)

    // 退出多选模式
    this.selectedSongIds.clear()
    this.isSelectMode = false
  }

  /**
   * 手动刷新扫描
   */
  private async refreshScan(): Promise<void> {
    if (this.isScanningMusic || !this.context) {
      return
    }

    console.info('Index', 'Manual refresh scan')

    if (!this.permissionGranted) {
      await this.checkAndRequestPermission()
    } else {
      await this.startScanMusic()
    }
  }

  /**
   * 通过文件选择器选择音乐文件
   */
  private async selectMusicFiles(): Promise<void> {
    if (this.isScanningMusic || !this.context) {
      return
    }

    console.info('Index', 'Opening file picker to select music')
    this.isScanningMusic = true
    this.scanStatusText = '正在选择文件...'

    const callback: ScanProgressCallback = {
      onStart: () => {
        console.info('Index', 'File selection started')
        this.scanStatusText = '正在处理选中的文件...'
      },
      onProgress: (current: number, total: number, currentFile?: string) => {
        this.scanProgress = current
        this.scanTotal = total
        if (total > 0) {
          const percent = Math.round((current / total) * 100)
          this.scanStatusText = `处理中 ${percent}% (${current}/${total})`
        }
      },
      onSongFound: (song: Song) => {
        console.info('Index', `Added song: ${song.title}`)
      },
      onComplete: (songs: Song[]) => {
        console.info('Index', `Selection completed, added ${songs.length} songs`)
        // 合并到现有列表
        if (songs.length > 0) {
          this.songs = [...this.songs, ...songs]
          this.updateGlobalState()
        }
        this.isScanningMusic = false
        this.isPageLoading = false
        this.scanStatusText = ''
      },
      onError: (error: string) => {
        console.error('Index', `File selection error: ${error}`)
        this.isScanningMusic = false
        this.isPageLoading = false
        this.scanStatusText = ''
      }
    }

    try {
      await this.musicScanService.addMusicByPicker(this.context, callback)
    } catch (error) {
      console.error('Index', `File selection failed: ${JSON.stringify(error)}`)
      this.isScanningMusic = false
      this.scanStatusText = ''
    }
  }

  /**
   * 获取当前歌曲对象
   */
  private getCurrentSong(): Song | null {
    return parseSongFromJson(this.currentSongJson)
  }

  /**
   * 获取播放模式名称
   */
  private getPlayModeName(mode: number): string {
    switch (mode) {
      case PlayMode.SEQUENCE:
        return '顺序播放'
      case PlayMode.LOOP:
        return '列表循环'
      case PlayMode.SINGLE:
        return '单曲循环'
      case PlayMode.SMART_SHUFFLE:
        return '智能随机'
      case PlayMode.TIME_AWARE:
        return '时间感知'
      case PlayMode.NIGHT_MODE:
        return '夜间模式'
      default:
        return '顺序播放'
    }
  }

  /**
   * 导航到播放器页面
   */
  private navigateToPlayer(): void {
    console.info('Index', 'Navigate to PlayerPage')
    router.pushUrl({ url: 'pages/PlayerPage' }, router.RouterMode.Single)
      .catch((err: Error) => {
        console.error('Index', `Navigate to player failed: ${err.message}`)
      })
  }

  /**
   * 导航到搜索页面
   */
  private navigateToSearch(): void {
    console.info('Index', 'Navigate to SearchPage')
    router.pushUrl({ url: 'pages/SearchPage' }, router.RouterMode.Single)
      .catch((err: Error) => {
        console.error('Index', `Navigate to search failed: ${err.message}`)
      })
  }

  /**
   * 导航到设置页面
   */
  private navigateToSettings(): void {
    console.info('Index', 'Navigate to SettingsPage')
    router.pushUrl({ url: 'pages/SettingsPage' }, router.RouterMode.Single)
      .catch((err: Error) => {
        console.error('Index', `Navigate to settings failed: ${err.message}`)
      })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部标题栏
        this.TitleBar()

        // Tab栏
        this.TabBar()

        // 内容区域
        if (this.currentTabIndex === 0) {
          this.SongListContent()
        } else if (this.currentTabIndex === 1) {
          this.FavoriteContent()
        } else if (this.currentTabIndex === 2) {
          this.PlaylistContent()
        } else {
          this.SettingsContent()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 底部迷你播放器
      if (this.currentSongJson && !this.isPlayerDetailExpanded) {
        MiniPlayer({
          currentSongJson: this.currentSongJson,
          isPlaying: this.isPlaying,
          isLoading: this.isLoading,
          playMode: this.playMode,
          progress: this.getProgressPercent(),
          currentPosition: this.currentPosition,
          duration: this.currentDuration > 0 ? this.currentDuration : (this.getCurrentSong()?.duration || 0),
          onPlayPauseClick: () => {
            console.info('Index', `MiniPlayer play/pause clicked, current isPlaying: ${this.isPlaying}`)
            this.playController.togglePlayPause()
          },
          onNextClick: () => {
            console.info('Index', 'MiniPlayer next clicked')
            this.playController.playNext()
          },
          onPlayerClick: () => {
            console.info('Index', 'MiniPlayer clicked - expand player detail panel')
            this.isPlayerDetailExpanded = true
          },
          onPlaylistClick: () => {
            console.info('Index', 'MiniPlayer playlist clicked')
            this.playQueueDialogController.open()
          },
          onPlayModeClick: async () => {
            console.info('Index', 'MiniPlayer play mode clicked')
            const newMode = await this.playController.togglePlayMode()
            promptAction.showToast({
              message: this.getPlayModeName(newMode),
              duration: 1500
            })
          },
          onSeek: (position: number) => {
            console.info('Index', `MiniPlayer seek to: ${position}ms`)
            this.playController.seekTo(position)
          }
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }

      // 播放详情面板（二级卡片）
      if (this.isPlayerDetailExpanded) {
        Column() {
          PlayerDetailPanel({
            isExpanded: $isPlayerDetailExpanded,
            onClose: () => {
              console.info('Index', 'Player detail panel closed')
              this.isPlayerDetailExpanded = false
            }
          })
        }
        .width('100%')
        .height('100%')
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.translate({ y: 1000 }).animation({
              duration: 350,
              curve: Curve.EaseOut
            }),
            TransitionEffect.translate({ y: 1000 }).animation({
              duration: 300,
              curve: Curve.EaseIn
            })
          )
        )
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 获取进度百分比
   * 优先使用实时 duration，其次使用歌曲元数据 duration
   */
  private getProgressPercent(): number {
    // 优先使用实时播放器的 duration
    const duration = this.currentDuration > 0 ? this.currentDuration : (this.getCurrentSong()?.duration || 0)
    if (duration === 0) {
      return 0
    }
    const percent = (this.currentPosition / duration) * 100
    // 确保百分比在 0-100 范围内
    return Math.min(100, Math.max(0, percent))
  }

  /**
   * 播放指定歌曲
   */
  private playSong(song: Song, index: number): void {
    console.info('Index', `Play song: ${song.title} at index ${index}`)
    // 使用 PlayController 播放，传入播放列表
    this.playController.playSong(song, index, this.songs)
  }

  /**
   * 播放下一首
   */
  private playNextSong(): void {
    console.info('Index', 'Play next song')
    this.playController.playNext()
  }

  @Builder
  TitleBar() {
    Row() {
      Text('音乐播放器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank()

      // 搜索按钮
      Image($r('app.media.ic_search'))
        .width(24)
        .height(24)
        .fillColor('#333333')
        .onClick(() => {
          console.info('Index', 'Search button clicked')
          this.navigateToSearch()
        })

      // 刷新/扫描按钮
      Image($r('app.media.ic_scan'))
        .width(24)
        .height(24)
        .fillColor(this.isScanningMusic ? '#999999' : '#333333')
        .margin({ left: 16 })
        .onClick(() => {
          if (!this.isScanningMusic) {
            console.info('Index', 'Scan button clicked')
            this.refreshScan()
          }
        })

      // 设置按钮
      Image($r('app.media.ic_more'))
        .width(24)
        .height(24)
        .fillColor('#333333')
        .margin({ left: 16 })
        .onClick(() => {
          console.info('Index', 'Settings button clicked')
          this.currentTabIndex = 3
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TabBar() {
    Row() {
      this.TabItem('歌曲', 0)
      this.TabItem('收藏', 1)
      this.TabItem('播放列表', 2)
      this.TabItem('设置', 3)
    }
    .width('100%')
    .height(44)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E0E0E0' })
  }

  @Builder
  TabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(this.currentTabIndex === index ? '#007AFF' : '#666666')
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)

      if (this.currentTabIndex === index) {
        Divider()
          .width(40)
          .height(2)
          .color('#007AFF')
          .margin({ top: 8 })
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      console.info('Index', `Tab clicked: ${title}`)
      this.currentTabIndex = index
    })
  }

  @Builder
  SongListContent() {
    if (this.isPageLoading || this.isScanningMusic) {
      // 加载/扫描中状态
      Column() {
        LoadingProgress()
          .width(48)
          .height(48)

        Text(this.scanStatusText || '加载中...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 16 })

        if (this.isScanningMusic && this.scanTotal > 0) {
          // 显示进度条
          Progress({ value: this.scanProgress, total: this.scanTotal, type: ProgressType.Linear })
            .width('60%')
            .height(4)
            .margin({ top: 16 })
            .color('#007AFF')

          Text(`${this.scanProgress} / ${this.scanTotal}`)
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.songs.length === 0) {
      // 空状态
      Column() {
        Image($r('app.media.ic_empty'))
          .width(80)
          .height(80)
          .fillColor('#CCCCCC')

        Text('暂无歌曲')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 16 })

        Text('可以扫描本地音乐或手动选择音频文件')
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 8 })

        Row() {
          Button('扫描音乐')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(20)
            .height(40)
            .width(110)
            .onClick(() => {
              this.refreshScan()
            })

          Button('选择文件')
            .fontSize(14)
            .fontColor('#007AFF')
            .backgroundColor('#FFFFFF')
            .borderRadius(20)
            .borderWidth(1)
            .borderColor('#007AFF')
            .height(40)
            .width(110)
            .margin({ left: 16 })
            .onClick(() => {
              this.selectMusicFiles()
            })
        }
        .margin({ top: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      // 歌曲列表
      Column() {
        // 歌曲数量统计
        Row() {
          Text(`共 ${this.songs.length} 首歌曲`)
            .fontSize(13)
            .fontColor('#999999')

          Blank()

          Row() {
            Image($r('app.media.ic_play'))
              .width(16)
              .height(16)
              .fillColor('#007AFF')
            Text('智能随机')
              .fontSize(13)
              .fontColor('#007AFF')
              .margin({ left: 4 })
          }
          .onClick(() => {
            console.info('Index', 'Smart shuffle clicked')
            if (this.songs.length > 0) {
              const randomIndex = Math.floor(Math.random() * this.songs.length)
              this.playSong(this.songs[randomIndex], randomIndex)
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')

        // 歌曲列表 - 使用 LazyForEach 实现懒加载
        List({ scroller: this.listScroller }) {
          LazyForEach(this.songDataSource, (song: Song, index: number) => {
            ListItem() {
              MusicItem({
                song: song,
                index: index,
                isPlaying: this.currentIndex === index && this.isPlaying,
                onItemClick: (s: Song, idx: number) => {
                  console.info('Index', `Song item clicked: ${s.title}`)
                  this.playSong(s, idx)
                },
                onMoreClick: (s: Song) => {
                  console.info('Index', `Song more button clicked: ${s.title}`)
                  // 显示更多操作菜单
                }
              })
            }
          }, (song: Song) => song.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ bottom: this.currentSongJson ? 70 : 0 })
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 88, endMargin: 16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .cachedCount(5) // 缓存5个列表项，提升滚动性能
      }
      .width('100%')
      .layoutWeight(1)
    }
  }

  @Builder
  FavoriteContent() {
    Column() {
      if (this.favoriteSongs.length === 0) {
        // 空状态
        Column() {
          Image($r('app.media.ic_favorite'))
            .width(80)
            .height(80)
            .fillColor('#CCCCCC')

          Text('暂无收藏歌曲')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16 })

          Text('在播放页点击爱心即可收藏歌曲')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 收藏歌曲统计
        Row() {
          Text(`共 ${this.favoriteSongs.length} 首收藏`)
            .fontSize(13)
            .fontColor('#999999')

          Blank()

          Row() {
            Image($r('app.media.ic_play'))
              .width(16)
              .height(16)
              .fillColor('#007AFF')
            Text('播放全部')
              .fontSize(13)
              .fontColor('#007AFF')
              .margin({ left: 4 })
          }
          .onClick(() => {
            console.info('Index', 'Play all favorites clicked')
            if (this.favoriteSongs.length > 0) {
              this.playController.playSong(this.favoriteSongs[0], 0, this.favoriteSongs)
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')

        // 收藏歌曲列表
        List() {
          ForEach(this.favoriteSongs, (song: Song, index: number) => {
            ListItem() {
              MusicItem({
                song: song,
                index: index,
                isPlaying: this.getCurrentSong()?.id === song.id && this.isPlaying,
                onItemClick: (s: Song, idx: number) => {
                  console.info('Index', `Favorite song clicked: ${s.title}`)
                  this.playController.playSong(s, idx, this.favoriteSongs)
                },
                onMoreClick: (s: Song) => {
                  console.info('Index', `Favorite song more clicked: ${s.title}`)
                }
              })
            }
          }, (song: Song) => song.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ bottom: this.currentSongJson ? 70 : 0 })
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 88, endMargin: 16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .onAppear(() => {
      // 每次切换到收藏 Tab 时刷新列表
      this.loadFavoriteSongs()
    })
  }

  @Builder
  PlaylistContent() {
    Column() {
      if (this.playlists.length === 0) {
        Column() {
          Image($r('app.media.ic_playlist'))
            .width(80)
            .height(80)
            .fillColor('#CCCCCC')
          Text('暂无播放列表')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 创建新播放列表按钮
        Row() {
          Image($r('app.media.ic_add'))
            .width(20)
            .height(20)
            .fillColor('#007AFF')
          Text('创建新播放列表')
            .fontSize(15)
            .fontColor('#007AFF')
            .margin({ left: 8 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          console.info('Index', 'Create new playlist clicked')
        })

        // 播放列表列表
        List() {
          ForEach(this.playlists, (playlist: Playlist) => {
            ListItem() {
              Row() {
                // 播放列表封面
                Image(playlist.coverUri || $r('app.media.ic_playlist'))
                  .width(56)
                  .height(56)
                  .borderRadius(6)
                  .backgroundColor('#F0F0F0')
                  .objectFit(ImageFit.Cover)

                // 播放列表信息
                Column() {
                  Text(playlist.name)
                    .fontSize(16)
                    .fontColor('#333333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  Text(`${playlist.songIds.length} 首歌曲`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                    .width('100%')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })

                // 更多按钮
                Image($r('app.media.ic_more'))
                  .width(24)
                  .height(24)
                  .fillColor('#CCCCCC')
                  .onClick(() => {
                    console.info('Index', `Playlist more clicked: ${playlist.name}`)
                  })
              }
              .width('100%')
              .height(72)
              .padding({ left: 16, right: 16 })
              .backgroundColor('#FFFFFF')
              .onClick(() => {
                console.info('Index', `Playlist clicked: ${playlist.name}`)
              })
            }
          }, (playlist: Playlist) => playlist.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ bottom: this.currentSongJson ? 70 : 0 })
        .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 84, endMargin: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  SettingsContent() {
    Column() {
      // 设置项列表
      List() {
        // 扫描音乐
        ListItem() {
          this.SettingItem('扫描本地音乐', 'ic_scan', () => {
            console.info('Index', 'Scan local music clicked')
            this.refreshScan()
          })
        }

        // 选择音乐文件
        ListItem() {
          this.SettingItem('选择音乐文件', 'ic_playlist', () => {
            console.info('Index', 'Select music files clicked')
            this.selectMusicFiles()
          })
        }

        // 定时关闭
        ListItem() {
          this.SettingItem('定时关闭', 'ic_mode_sequence', () => {
            console.info('Index', 'Sleep timer clicked')
            this.navigateToSettings()
          })
        }

        // 更多设置
        ListItem() {
          this.SettingItem('更多设置', 'ic_more', () => {
            console.info('Index', 'More settings clicked')
            this.navigateToSettings()
          })
        }

        // 关于
        ListItem() {
          this.SettingItem('关于', 'ic_playing', () => {
            console.info('Index', 'About clicked')
            this.navigateToSettings()
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .padding({ bottom: this.currentSongJson ? 70 : 0 })
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 56, endMargin: 0 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  SettingItem(title: string, icon: string, onClick: () => void) {
    Row() {
      Image($r(`app.media.${icon}`))
        .width(24)
        .height(24)
        .fillColor('#666666')

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .margin({ left: 16 })
        .layoutWeight(1)

      Image($r('app.media.ic_back'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
        .rotate({ angle: 180 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .onClick(() => onClick())
  }
}
