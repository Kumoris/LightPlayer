import { router, promptAction } from '@kit.ArkUI'
import { Song } from '../model/Song'
import { SongListViewModel } from '../viewmodel/SongListViewModel'
import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { GlobalPlayState } from '../common/GlobalPlayState'
import { PreferencesManager } from '../data/preferences/PreferencesManager'
import { TimeUtils } from '../common/utils/TimeUtils'

/**
 * 搜索页面
 * 支持本地搜索、搜索历史、结果高亮
 */
@Entry
@Component
struct SearchPage {
  @State private songListVM: SongListViewModel = SongListViewModel.getInstance()
  @State private playerVM: PlayerViewModel = PlayerViewModel.getInstance()
  @State private searchText: string = ''
  @State private searchResults: Song[] = []
  @State private searchHistory: string[] = []
  @State private showHistory: boolean = true

  private preferencesManager: PreferencesManager = PreferencesManager.getInstance()

  aboutToAppear(): void {
    console.info('SearchPage', 'aboutToAppear - Page loaded')
    this.loadSearchHistory()
  }

  /**
   * 加载搜索历史
   */
  private async loadSearchHistory(): Promise<void> {
    this.searchHistory = await this.preferencesManager.getSearchHistory()
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    console.info('SearchPage', 'Go back clicked')
    try {
      router.back()
    } catch (err) {
      console.error('SearchPage', `Go back failed: ${err}`)
    }
  }

  /**
   * 执行搜索
   */
  private async doSearch(): Promise<void> {
    if (this.searchText.trim().length === 0) {
      this.searchResults = []
      this.showHistory = true
      return
    }

    this.showHistory = false
    console.info('SearchPage', `Searching for: ${this.searchText}`)

    // 本地过滤
    const keyword = this.searchText.toLowerCase()
    this.searchResults = this.songListVM.songs.filter((song: Song) =>
    song.title.toLowerCase().includes(keyword) ||
    song.artist.toLowerCase().includes(keyword) ||
    song.album.toLowerCase().includes(keyword)
    )

    console.info('SearchPage', `Found ${this.searchResults.length} results`)
  }

  /**
   * 提交搜索（按回车）
   */
  private async submitSearch(): Promise<void> {
    if (this.searchText.trim().length > 0) {
      await this.preferencesManager.addSearchHistory(this.searchText.trim())
      await this.loadSearchHistory()
    }
  }

  /**
   * 使用历史关键词搜索
   */
  private async searchWithKeyword(keyword: string): Promise<void> {
    this.searchText = keyword
    await this.doSearch()
    await this.submitSearch()
  }

  /**
   * 删除历史记录
   */
  private async deleteHistoryItem(keyword: string): Promise<void> {
    await this.preferencesManager.removeSearchHistory(keyword)
    await this.loadSearchHistory()
  }

  /**
   * 清空历史记录
   */
  private async clearHistory(): Promise<void> {
    await this.preferencesManager.clearSearchHistory()
    this.searchHistory = []
  }

  /**
   * 播放歌曲
   */
  private playSong(song: Song, index: number): void {
    console.info('SearchPage', `Search result clicked: ${song.title}`)
    // 同时更新全局状态
    GlobalPlayState.getInstance().setSongList(this.searchResults)
    GlobalPlayState.getInstance().playSong(song, index)
    this.playerVM.playFromList(this.searchResults, index)
  }

  build() {
    Column() {
      // 搜索栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => {
            this.goBack()
          })

        TextInput({ placeholder: '搜索歌曲、艺术家、专辑', text: this.searchText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .padding({ left: 16, right: 16 })
          .margin({ left: 12 })
          .onChange((value: string) => {
            this.searchText = value
            this.doSearch()
          })
          .onSubmit(() => {
            this.submitSearch()
          })

        Text('取消')
          .fontSize(14)
          .fontColor('#007AFF')
          .margin({ left: 12 })
          .onClick(() => {
            console.info('SearchPage', 'Cancel button clicked')
            this.goBack()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 内容区域
      if (this.showHistory && this.searchText.length === 0) {
        // 搜索历史
        this.SearchHistory()
      } else if (this.searchResults.length === 0) {
        // 无结果
        this.EmptyResult()
      } else {
        // 结果列表
        this.SearchResults()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SearchHistory() {
    Column() {
      if (this.searchHistory.length > 0) {
        // 历史标题
        Row() {
          Text('搜索历史')
            .fontSize(14)
            .fontColor('#666666')

          Blank()

          Text('清空')
            .fontSize(13)
            .fontColor('#999999')
            .onClick(() => {
              promptAction.showDialog({
                title: '清空搜索历史',
                message: '确定要清空所有搜索历史吗？',
                buttons: [
                  { text: '取消', color: '#666666' },
                  { text: '确定', color: '#007AFF' }
                ]
              }).then((result) => {
                if (result.index === 1) {
                  this.clearHistory()
                }
              }).catch((err: Error) => {
                console.error('SearchPage', `Show dialog failed: ${err.message}`)
              })
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })

        // 历史记录列表
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.searchHistory, (keyword: string) => {
            Row() {
              Text(keyword)
                .fontSize(13)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Image($r('app.media.ic_close'))
                .width(14)
                .height(14)
                .fillColor('#CCCCCC')
                .margin({ left: 6 })
                .onClick(() => {
                  this.deleteHistoryItem(keyword)
                })
            }
            .height(32)
            .padding({ left: 12, right: 8 })
            .margin({ right: 8, bottom: 8 })
            .backgroundColor('#F0F0F0')
            .borderRadius(16)
            .onClick(() => {
              this.searchWithKeyword(keyword)
            })
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      } else {
        // 无历史记录
        Column() {
          Image($r('app.media.ic_search'))
            .width(60)
            .height(60)
            .fillColor('#DDDDDD')

          Text('输入关键词搜索音乐')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  EmptyResult() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(60)
        .height(60)
        .fillColor('#CCCCCC')
      Text('未找到相关歌曲')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 16 })
      Text(`没有找到与"${this.searchText}"相关的结果`)
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SearchResults() {
    Column() {
      // 结果数量
      Row() {
        Text(`找到 ${this.searchResults.length} 首相关歌曲`)
          .fontSize(13)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // 结果列表
      List() {
        ForEach(this.searchResults, (song: Song, index: number) => {
          ListItem() {
            this.SearchResultItem(song, index)
          }
        }, (song: Song) => song.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 76, endMargin: 16 })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  SearchResultItem(song: Song, index: number) {
    Row() {
      // 专辑封面
      Image(song.albumArt || $r('app.media.default_album'))
        .width(50)
        .height(50)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)

      // 歌曲信息
      Column() {
        // 歌曲名称（高亮关键词）
        this.HighlightText(song.title, this.searchText)

        // 艺术家 - 专辑（高亮关键词）
        Row() {
          this.HighlightText(song.artist, this.searchText, 12, '#999999', '#007AFF')
          Text(' - ')
            .fontSize(12)
            .fontColor('#999999')
          this.HighlightText(song.album, this.searchText, 12, '#999999', '#007AFF')
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 时长
      Text(TimeUtils.formatDuration(song.duration))
        .fontSize(12)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.playSong(song, index)
    })
  }

  @Builder
  HighlightText(text: string, keyword: string, fontSize: number = 15, normalColor: string = '#333333', highlightColor: string = '#007AFF') {
    if (!keyword || keyword.trim().length === 0) {
      Text(text)
        .fontSize(fontSize)
        .fontColor(normalColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    } else {
      // 分割文本并高亮关键词
      Text() {
        ForEach(this.splitTextForHighlight(text, keyword), (part: HighlightPart) => {
          if (part.isHighlight) {
            Span(part.text)
              .fontSize(fontSize)
              .fontColor(highlightColor)
              .fontWeight(FontWeight.Medium)
          } else {
            Span(part.text)
              .fontSize(fontSize)
              .fontColor(normalColor)
          }
        })
      }
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
  }

  /**
   * 分割文本用于高亮显示
   */
  private splitTextForHighlight(text: string, keyword: string): HighlightPart[] {
    const parts: HighlightPart[] = []
    const lowerText = text.toLowerCase()
    const lowerKeyword = keyword.toLowerCase()

    let lastIndex = 0
    let index = lowerText.indexOf(lowerKeyword)

    while (index !== -1) {
      // 添加关键词之前的部分
      if (index > lastIndex) {
        parts.push({ text: text.substring(lastIndex, index), isHighlight: false })
      }
      // 添加高亮的关键词
      parts.push({ text: text.substring(index, index + keyword.length), isHighlight: true })

      lastIndex = index + keyword.length
      index = lowerText.indexOf(lowerKeyword, lastIndex)
    }

    // 添加剩余部分
    if (lastIndex < text.length) {
      parts.push({ text: text.substring(lastIndex), isHighlight: false })
    }

    return parts
  }
}

/**
 * 高亮文本部分接口
 */
interface HighlightPart {
  text: string
  isHighlight: boolean
}
