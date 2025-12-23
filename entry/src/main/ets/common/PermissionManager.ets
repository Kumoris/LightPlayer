import { abilityAccessCtrl, bundleManager, Permissions, common } from '@kit.AbilityKit'

/**
 * 权限请求结果
 */
export interface PermissionResult {
  granted: boolean
  permissions: string[]
  deniedPermissions: string[]
}

/**
 * 权限管理器
 * 处理运行时权限请求
 */
export class PermissionManager {
  private static instance: PermissionManager | null = null
  private atManager: abilityAccessCtrl.AtManager

  private constructor() {
    this.atManager = abilityAccessCtrl.createAtManager()
  }

  /**
   * 获取单例实例
   */
  static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager()
    }
    return PermissionManager.instance
  }

  /**
   * 检查单个权限是否已授予
   */
  async checkPermission(permission: Permissions): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const tokenId = bundleInfo.appInfo.accessTokenId

      const grantStatus = this.atManager.checkAccessTokenSync(tokenId, permission)
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (error) {
      console.error('PermissionManager', `Check permission failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查多个权限
   */
  async checkPermissions(permissions: Permissions[]): Promise<Map<string, boolean>> {
    const result = new Map<string, boolean>()

    for (const permission of permissions) {
      const granted = await this.checkPermission(permission)
      result.set(permission, granted)
    }

    return result
  }

  /**
   * 请求单个权限
   */
  async requestPermission(context: common.UIAbilityContext, permission: Permissions): Promise<boolean> {
    try {
      // 先检查是否已授予
      const alreadyGranted = await this.checkPermission(permission)
      if (alreadyGranted) {
        console.info('PermissionManager', `Permission already granted: ${permission}`)
        return true
      }

      // 请求权限
      const result = await this.atManager.requestPermissionsFromUser(context, [permission])

      if (result.authResults.length > 0) {
        const granted = result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        console.info('PermissionManager', `Permission ${permission} result: ${granted}`)
        return granted
      }

      return false
    } catch (error) {
      console.error('PermissionManager', `Request permission failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 请求多个权限
   */
  async requestPermissions(context: common.UIAbilityContext, permissions: Permissions[]): Promise<PermissionResult> {
    const result: PermissionResult = {
      granted: true,
      permissions: [],
      deniedPermissions: []
    }

    try {
      // 先检查哪些权限需要请求
      const permissionsToRequest: Permissions[] = []
      for (const permission of permissions) {
        const alreadyGranted = await this.checkPermission(permission)
        if (alreadyGranted) {
          result.permissions.push(permission)
        } else {
          permissionsToRequest.push(permission)
        }
      }

      // 如果有需要请求的权限
      if (permissionsToRequest.length > 0) {
        const requestResult = await this.atManager.requestPermissionsFromUser(context, permissionsToRequest)

        for (let i = 0; i < permissionsToRequest.length; i++) {
          const permission = permissionsToRequest[i]
          const granted = requestResult.authResults[i] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED

          if (granted) {
            result.permissions.push(permission)
          } else {
            result.deniedPermissions.push(permission)
            result.granted = false
          }
        }
      }

      console.info('PermissionManager', `Request permissions result: granted=${result.granted}, denied=${result.deniedPermissions.join(', ')}`)
    } catch (error) {
      console.error('PermissionManager', `Request permissions failed: ${JSON.stringify(error)}`)
      result.granted = false
    }

    return result
  }

  /**
   * 检查音频读取权限
   */
  async checkAudioReadPermission(): Promise<boolean> {
    // 尝试检查 READ_AUDIO 权限
    const hasReadAudio = await this.checkPermission('ohos.permission.READ_AUDIO' as Permissions)
    if (hasReadAudio) {
      return true
    }
    // 回退检查 READ_MEDIA 权限
    return await this.checkPermission('ohos.permission.READ_MEDIA' as Permissions)
  }

  /**
   * 请求音频读取权限
   */
  async requestAudioReadPermission(context: common.UIAbilityContext): Promise<boolean> {
    // 先尝试请求 READ_AUDIO
    const hasReadAudio = await this.requestPermission(context, 'ohos.permission.READ_AUDIO' as Permissions)
    if (hasReadAudio) {
      return true
    }
    // 回退请求 READ_MEDIA
    return await this.requestPermission(context, 'ohos.permission.READ_MEDIA' as Permissions)
  }

  /**
   * 检查媒体读取权限 (兼容旧API)
   */
  async checkMediaReadPermission(): Promise<boolean> {
    return await this.checkAudioReadPermission()
  }

  /**
   * 请求媒体读取权限 (兼容旧API)
   */
  async requestMediaReadPermission(context: common.UIAbilityContext): Promise<boolean> {
    return await this.requestAudioReadPermission(context)
  }

  /**
   * 请求音乐播放相关的所有权限
   */
  async requestMusicPlayerPermissions(context: common.UIAbilityContext): Promise<PermissionResult> {
    const permissions: Permissions[] = [
      'ohos.permission.READ_AUDIO' as Permissions,
      'ohos.permission.READ_MEDIA' as Permissions
    ]
    return await this.requestPermissions(context, permissions)
  }
}
