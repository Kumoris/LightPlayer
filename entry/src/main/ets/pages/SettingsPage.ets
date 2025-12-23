import { router, promptAction } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { PreferencesManager, AudioQuality } from '../data/preferences/PreferencesManager'
import { MusicScanService } from '../service/MusicScanService'
import { AudioPlayerService } from '../service/AudioPlayerService'

/**
 * 设置页面
 * 包含：扫描目录配置、定时关闭、音质设置、关于页面
 */
@Entry
@Component
struct SettingsPage {
  @State private scanPaths: string[] = []
  @State private sleepTimerMinutes: number = 0
  @State private sleepTimerRemaining: number = 0
  @State private audioQuality: AudioQuality = AudioQuality.HIGH
  @State private showSleepTimerDialog: boolean = false
  @State private showAudioQualityDialog: boolean = false
  @State private showAboutDialog: boolean = false
  @State private isScanning: boolean = false

  private preferencesManager: PreferencesManager = PreferencesManager.getInstance()
  private musicScanService: MusicScanService = MusicScanService.getInstance()
  private audioPlayerService: AudioPlayerService = AudioPlayerService.getInstance()
  private context: common.UIAbilityContext | null = null
  private sleepTimerCheckInterval: number = -1

  // 定时关闭选项（分钟）
  private sleepTimerOptions: number[] = [0, 15, 30, 45, 60, 90, 120]

  aboutToAppear(): void {
    console.info('SettingsPage', 'aboutToAppear')
    const ctx = getContext(this)
    if (ctx) {
      this.context = ctx as common.UIAbilityContext
    }
    this.loadSettings()
    this.startSleepTimerCheck()
  }

  aboutToDisappear(): void {
    this.stopSleepTimerCheck()
  }

  /**
   * 加载设置
   */
  private async loadSettings(): Promise<void> {
    this.scanPaths = await this.preferencesManager.getScanPaths()
    this.audioQuality = await this.preferencesManager.getAudioQuality()
    this.sleepTimerRemaining = await this.preferencesManager.getSleepTimerRemaining()
    if (this.sleepTimerRemaining > 0) {
      this.sleepTimerMinutes = Math.ceil(this.sleepTimerRemaining / 60000)
    }
  }

  /**
   * 启动定时关闭检查
   */
  private startSleepTimerCheck(): void {
    this.sleepTimerCheckInterval = setInterval(async () => {
      this.sleepTimerRemaining = await this.preferencesManager.getSleepTimerRemaining()
      if (this.sleepTimerRemaining <= 0 && this.sleepTimerMinutes > 0) {
        // 定时器到期，停止播放
        await this.audioPlayerService.stop()
        this.sleepTimerMinutes = 0
      }
    }, 1000)
  }

  /**
   * 停止定时关闭检查
   */
  private stopSleepTimerCheck(): void {
    if (this.sleepTimerCheckInterval !== -1) {
      clearInterval(this.sleepTimerCheckInterval)
      this.sleepTimerCheckInterval = -1
    }
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    try {
      router.back()
    } catch (err) {
      console.error('SettingsPage', `Go back failed: ${err}`)
    }
  }

  /**
   * 设置定时关闭
   */
  private async setSleepTimer(minutes: number): Promise<void> {
    await this.preferencesManager.setSleepTimer(minutes)
    this.sleepTimerMinutes = minutes
    if (minutes > 0) {
      this.sleepTimerRemaining = minutes * 60 * 1000
    } else {
      this.sleepTimerRemaining = 0
    }
    this.showSleepTimerDialog = false
  }

  /**
   * 设置音质
   */
  private async setAudioQuality(quality: AudioQuality): Promise<void> {
    await this.preferencesManager.setAudioQuality(quality)
    this.audioQuality = quality
    this.showAudioQualityDialog = false
  }

  /**
   * 获取音质名称
   */
  private getAudioQualityName(quality: AudioQuality): string {
    switch (quality) {
      case AudioQuality.LOW:
        return '低音质'
      case AudioQuality.MEDIUM:
        return '中等音质'
      case AudioQuality.HIGH:
        return '高音质'
      case AudioQuality.LOSSLESS:
        return '无损音质'
      default:
        return '高音质'
    }
  }

  /**
   * 获取剩余时间显示
   */
  private getSleepTimerDisplay(): string {
    if (this.sleepTimerRemaining <= 0) {
      return '关闭'
    }
    const minutes = Math.floor(this.sleepTimerRemaining / 60000)
    const seconds = Math.floor((this.sleepTimerRemaining % 60000) / 1000)
    if (minutes > 0) {
      return `${minutes}分${seconds}秒后关闭`
    }
    return `${seconds}秒后关闭`
  }

  /**
   * 清除播放历史
   */
  private async clearPlayHistory(): Promise<void> {
    await this.preferencesManager.clearPlayHistory()
    promptAction.showToast({
      message: '播放历史已清除',
      duration: 2000
    })
  }

  /**
   * 清除搜索历史
   */
  private async clearSearchHistory(): Promise<void> {
    await this.preferencesManager.clearSearchHistory()
    promptAction.showToast({
      message: '搜索历史已清除',
      duration: 2000
    })
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopBar()

      // 设置列表
      List() {
        // 音乐扫描设置分组
        ListItemGroup({ header: this.GroupHeader('音乐库') }) {
          ListItem() {
            this.SettingItem('扫描本地音乐', this.isScanning ? '扫描中...' : '从设备选择音乐文件', () => {
              if (!this.isScanning && this.context) {
                this.isScanning = true
                this.musicScanService.addMusicByPicker(this.context, {
                  onComplete: () => {
                    this.isScanning = false
                  },
                  onError: () => {
                    this.isScanning = false
                  }
                })
              }
            })
          }

          ListItem() {
            this.SettingItem('清除播放历史', '', () => {
              promptAction.showDialog({
                title: '清除播放历史',
                message: '确定要清除所有播放历史吗？',
                buttons: [
                  { text: '取消', color: '#666666' },
                  { text: '确定', color: '#007AFF' }
                ]
              }).then((result) => {
                if (result.index === 1) {
                  this.clearPlayHistory()
                }
              }).catch((err: Error) => {
                console.error('SettingsPage', `Show dialog failed: ${err.message}`)
              })
            })
          }

          ListItem() {
            this.SettingItem('清除搜索历史', '', () => {
              promptAction.showDialog({
                title: '清除搜索历史',
                message: '确定要清除所有搜索历史吗？',
                buttons: [
                  { text: '取消', color: '#666666' },
                  { text: '确定', color: '#007AFF' }
                ]
              }).then((result) => {
                if (result.index === 1) {
                  this.clearSearchHistory()
                }
              }).catch((err: Error) => {
                console.error('SettingsPage', `Show dialog failed: ${err.message}`)
              })
            })
          }
        }

        // 播放设置分组
        ListItemGroup({ header: this.GroupHeader('播放') }) {
          ListItem() {
            this.SettingItem('播放音质', this.getAudioQualityName(this.audioQuality), () => {
              this.showAudioQualityDialog = true
            })
          }

          ListItem() {
            this.SettingItem('定时关闭', this.getSleepTimerDisplay(), () => {
              this.showSleepTimerDialog = true
            })
          }
        }

        // 关于分组
        ListItemGroup({ header: this.GroupHeader('关于') }) {
          ListItem() {
            this.SettingItem('版本', '1.0.0', () => {})
          }

          ListItem() {
            this.SettingItem('关于应用', '', () => {
              this.showAboutDialog = true
            })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .divider({ strokeWidth: 0.5, color: '#E8E8E8', startMargin: 16, endMargin: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .bindSheet($$this.showSleepTimerDialog, this.SleepTimerSheet(), {
      height: 360,
      showClose: true,
      dragBar: true,
      title: { title: '定时关闭' }
    })
    .bindSheet($$this.showAudioQualityDialog, this.AudioQualitySheet(), {
      height: 320,
      showClose: true,
      dragBar: true,
      title: { title: '播放音质' }
    })
    .bindSheet($$this.showAboutDialog, this.AboutSheet(), {
      height: 400,
      showClose: true,
      dragBar: true,
      title: { title: '关于' }
    })
  }

  @Builder
  TopBar() {
    Row() {
      Image($r('app.media.ic_back'))
        .width(24)
        .height(24)
        .fillColor('#333333')
        .onClick(() => {
          this.goBack()
        })

      Text('设置')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位
      Row()
        .width(24)
        .height(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  GroupHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(13)
        .fontColor('#999999')
    }
    .width('100%')
    .height(40)
    .padding({ left: 16 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SettingItem(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)

      if (value) {
        Text(value)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ right: 8 })
      }

      Image($r('app.media.ic_back'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
        .rotate({ angle: 180 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .onClick(() => onClick())
  }

  @Builder
  SleepTimerSheet() {
    Column() {
      ForEach(this.sleepTimerOptions, (minutes: number) => {
        Row() {
          Text(minutes === 0 ? '关闭' : `${minutes} 分钟`)
            .fontSize(16)
            .fontColor('#333333')
            .layoutWeight(1)

          if ((minutes === 0 && this.sleepTimerRemaining <= 0) ||
              (minutes > 0 && this.sleepTimerMinutes === minutes)) {
            Image($r('app.media.ic_playing'))
              .width(20)
              .height(20)
              .fillColor('#007AFF')
          }
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.setSleepTimer(minutes)
        })
      })
    }
    .width('100%')
  }

  @Builder
  AudioQualitySheet() {
    Column() {
      ForEach([AudioQuality.LOW, AudioQuality.MEDIUM, AudioQuality.HIGH, AudioQuality.LOSSLESS], (quality: AudioQuality) => {
        Row() {
          Column() {
            Text(this.getAudioQualityName(quality))
              .fontSize(16)
              .fontColor('#333333')

            Text(this.getAudioQualityDescription(quality))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (this.audioQuality === quality) {
            Image($r('app.media.ic_playing'))
              .width(20)
              .height(20)
              .fillColor('#007AFF')
          }
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.setAudioQuality(quality)
        })
      })
    }
    .width('100%')
  }

  /**
   * 获取音质描述
   */
  private getAudioQualityDescription(quality: AudioQuality): string {
    switch (quality) {
      case AudioQuality.LOW:
        return '节省流量，适合网络较差时'
      case AudioQuality.MEDIUM:
        return '平衡音质与流量'
      case AudioQuality.HIGH:
        return '高清音质，推荐使用'
      case AudioQuality.LOSSLESS:
        return '无损音质，需要更多存储空间'
      default:
        return ''
    }
  }

  @Builder
  AboutSheet() {
    Column() {
      // 应用图标
      Image($r('app.media.ic_playing'))
        .width(80)
        .height(80)
        .fillColor('#007AFF')
        .margin({ top: 20 })

      // 应用名称
      Text('音乐播放器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 16 })

      // 版本号
      Text('版本 1.0.0')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })

      // 描述
      Text('一款简洁优雅的本地音乐播放器')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 24 })
        .textAlign(TextAlign.Center)

      // 功能特点
      Column() {
        this.FeatureItem('支持多种音频格式 (MP3, FLAC, WAV, AAC等)')
        this.FeatureItem('后台播放与通知栏控制')
        this.FeatureItem('多种播放模式 (顺序、循环、随机、单曲)')
        this.FeatureItem('定时关闭功能')
      }
      .margin({ top: 20 })
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 24, right: 24 })

      // 版权信息
      Text('Copyright 2024')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 30 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  FeatureItem(text: string) {
    Row() {
      Circle()
        .width(6)
        .height(6)
        .fill('#007AFF')

      Text(text)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 8 })
  }
}
