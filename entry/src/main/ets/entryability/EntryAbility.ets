import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'
import { DatabaseHelper } from '../data/database/DatabaseHelper'
import { PreferencesManager } from '../data/preferences/PreferencesManager'
import { AudioPlayerService } from '../service/AudioPlayerService'
import { GlobalPlayState } from '../common/GlobalPlayState'
import { PlayController } from '../common/PlayController'
import { SleepTimerService } from '../service/SleepTimerService'

const DOMAIN = 0x0001
const TAG = 'MusicPlayer'

export default class EntryAbility extends UIAbility {
  private isInBackground: boolean = false

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate')

    try {
      // 设置颜色模式
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode: %{public}s', JSON.stringify(err))
    }

    // 初始化全局播放状态（必须在加载页面前初始化）
    GlobalPlayState.getInstance().initializeStorage()
    hilog.info(DOMAIN, TAG, 'GlobalPlayState initialized successfully')

    // 初始化数据库
    const dbResult = await DatabaseHelper.getInstance().initialize(this.context)
    if (dbResult) {
      hilog.info(DOMAIN, TAG, 'Database initialized successfully')
    } else {
      hilog.error(DOMAIN, TAG, 'Failed to initialize database')
    }

    // 初始化偏好设置
    const prefResult = await PreferencesManager.getInstance().initialize(this.context)
    if (prefResult) {
      hilog.info(DOMAIN, TAG, 'PreferencesManager initialized successfully')
    } else {
      hilog.error(DOMAIN, TAG, 'Failed to initialize preferences')
    }

    // 初始化播放器服务（传入上下文用于后台任务）
    const playerResult = await AudioPlayerService.getInstance().initialize(this.context)
    if (playerResult) {
      hilog.info(DOMAIN, TAG, 'AudioPlayerService initialized successfully')

      // 初始化播放控制器（连接 Service 和 GlobalState）
      PlayController.getInstance().initialize()
      hilog.info(DOMAIN, TAG, 'PlayController initialized successfully')

      // 初始化定时关闭服务
      await SleepTimerService.getInstance().initialize()
      hilog.info(DOMAIN, TAG, 'SleepTimerService initialized successfully')
    } else {
      hilog.error(DOMAIN, TAG, 'Failed to initialize audio player')
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy')

    // 释放定时关闭服务
    SleepTimerService.getInstance().release()

    // 释放播放控制器
    PlayController.getInstance().release()

    // 释放播放器资源
    AudioPlayerService.getInstance().release()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate')

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(DOMAIN, TAG, 'Content loaded successfully')
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground')
    this.isInBackground = false

    // 应用返回前台时，同步播放状态到 UI
    // GlobalPlayState 会自动通过 AppStorage 同步状态
    hilog.info(DOMAIN, TAG, 'App returned to foreground, state synchronized')
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground')
    this.isInBackground = true

    // 应用切换到后台时，如果正在播放，后台任务已在 play() 时启动
    // 播放会继续在后台进行
    hilog.info(DOMAIN, TAG, 'App moved to background, playback will continue if active')
  }
}
