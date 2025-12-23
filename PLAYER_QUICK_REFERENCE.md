# HarmonyOS音乐播放器 - 快速参考指南

## 文件速查表

| 功能模块 | 文件路径 | 主要功能 |
|---------|---------|---------|
| **时间格式化** | `/entry/src/main/ets/common/utils/TimeUtils.ets` | 毫秒→字符串转换 |
| **迷你播放器** | `/entry/src/main/ets/components/MiniPlayer.ets` | 底部悬浮播放器 (52px高) |
| **详情面板** | `/entry/src/main/ets/components/PlayerDetailPanel.ets` | 二级展开卡片 |
| **播放页面** | `/entry/src/main/ets/pages/PlayerPage.ets` | 全屏播放界面 |
| **播放控制** | `/entry/src/main/ets/components/PlayerControls.ets` | 控制按钮组件 |
| **播放器模型** | `/entry/src/main/ets/model/PlayState.ets` | 播放模式和状态枚举 |
| **歌曲模型** | `/entry/src/main/ets/model/Song.ets` | 歌曲数据结构 |
| **播放控制器** | `/entry/src/main/ets/common/PlayController.ets` | 播放控制业务逻辑 |
| **全局状态** | `/entry/src/main/ets/common/GlobalPlayState.ets` | AppStorage 管理 |
| **播放队列** | `/entry/src/main/ets/service/PlayQueueService.ets` | 队列和模式管理 |
| **图标资源** | `/entry/src/main/resources/base/media/` | SVG图标库 |

---

## 各功能细节速查

### 1. 时间显示

#### 格式化方法
```
TimeUtils.formatDuration(ms)     → "2:15" 或 "1:02:30" (自适应)
TimeUtils.formatDurationLong(ms) → "1:02:30" (强制长格式)
```

#### 显示位置
| 组件 | 格式 | 字号 | 颜色 |
|------|------|------|------|
| MiniPlayer | "2:15 / 4:30" | 10 | #007AFF |
| PlayerPage | 左: 当前时间, 右: 总长 | 12 | rgba(255,255,255,0.6) |
| PlayerDetailPanel | 左: 当前时间, 右: 总长 | 11 | rgba(255,255,255,0.6) |

---

### 2. 进度条

#### Slider 配置
```
范围:       0-100 (百分比)
精度:       0.1
样式:       SliderStyle.OutSet
拖动回调:   3个触发点 (Begin/Moving/End)
```

#### 色彩方案
| 组件 | 块颜色 | 轨道颜色 | 已播放颜色 |
|------|--------|---------|----------|
| MiniPlayer | #007AFF | #E8E8E8 | #007AFF |
| PlayerPage | #FFFFFF | rgba(255,255,255,0.3) | #FFFFFF |
| PlayerDetailPanel | #FFFFFF | rgba(255,255,255,0.3) | #FFFFFF |

---

### 3. 播放状态反馈

#### 状态枚举
```typescript
IDLE      → 空闲
PREPARED  → 已准备
PLAYING   → 播放中 (旋转 + 图标切换)
PAUSED    → 已暂停 (停止旋转)
STOPPED   → 已停止
ERROR     → 出错
```

#### 视觉反馈
```
播放/暂停  → ic_play / ic_pause 图标切换
按压效果   → 背景色 #FFFFFF → #F0F0F0
封面旋转   → 播放时每16ms增加0.5度 (60fps)
波形指示   → 三条竖线 (中:9px, 边:5px)
```

---

### 4. 图标使用

#### 核心图标
| 图标 | 文件名 | 用途 | 使用组件 |
|------|--------|------|---------|
| 播放 | ic_play.svg | 播放按钮 | MiniPlayer, PlayerPage |
| 暂停 | ic_pause.svg | 暂停按钮 | MiniPlayer, PlayerPage |
| 下一首 | ic_next.svg | 下一首 | MiniPlayer, PlayerPage |
| 上一首 | ic_previous.svg | 上一首 | MiniPlayer, PlayerPage |
| 播放列表 | ic_playlist.svg | 打开列表 | MiniPlayer, PlayerPage |

#### 播放模式图标
```
ic_mode_sequence.svg  → 顺序播放 (0)
ic_mode_loop.svg      → 列表循环 (1)
ic_mode_single.svg    → 单曲循环 (2)
ic_mode_shuffle.svg   → 随机播放 (3)
```

#### 问题: 图标复用
```
ic_scan.svg   → 收藏 + 下载 (有歧义)
ic_more.svg   → 菜单 + 评论 (有歧义)
ic_search.svg → 搜索 + 分享 (有歧义)
```

---

### 5. 异常数据处理

#### 空值显示预设
```typescript
song.title   ?? '未在播放'      (MiniPlayer)
song.artist  ?? '点击选择歌曲'  (MiniPlayer)
song.album   ?? '未知专辑'      (PlayerPage/Panel)
song.albumArt?? default_album.svg
song.duration || 0               (默认值)
```

#### 容错处理
```
负数时长  → 显示 '0:00'
0时长     → 进度条为 0%
Null歌曲 → 显示占位符文本
```

---

### 6. 播放模式

#### 模式定义
```typescript
PlayMode.SEQUENCE (0) → 顺序播放，到末尾停止
PlayMode.LOOP     (1) → 列表循环，末尾回到首部
PlayMode.SINGLE   (2) → 单曲循环，同一首无限
PlayMode.SHUFFLE  (3) → 随机播放，按随机顺序
```

#### 切换流程
```
顺序播放 → 列表循环 → 单曲循环 → 随机播放 → 顺序播放 (循环)
```

#### 切换入口
| 位置 | 按钮尺寸 | 说明 |
|------|---------|------|
| PlayerPage | 26x26 | 控制按钮行左侧 |
| PlayerDetailPanel | 24x24 | 控制按钮行左侧 |
| PlayerControls | 28x28 | 单独组件模式 |

#### 模式提示
```
PlayerPage:      11号字, rgba(255,255,255,0.5), margin-top:16
PlayerDetailPanel: 10号字, rgba(255,255,255,0.5), margin-top:12
```

---

## 核心数据流

### 播放状态更新流程
```
AudioPlayerService
        ↓
    (事件回调)
        ↓
 PlayController (监听器实现)
        ↓
GlobalPlayState (AppStorage 存储)
        ↓
    @StorageLink
        ↓
  UI 组件 (自动刷新)
```

### 播放模式切换流程
```
点击模式按钮
    ↓
togglePlayMode()
    ↓
PlayQueueService.togglePlayMode()
    ↓
循环切换到下一个模式
    ↓
GlobalPlayState 更新
    ↓
UI 刷新 (图标 + 文字)
```

---

## 常见问题排查

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 时间显示为 "0:00" | duration 为 0 或负数 | 检查 Song.duration 值 |
| 进度条卡住 | isDragging 状态错误 | 检查 SliderChangeMode.End 处理 |
| 旋转不停 | stopRotation() 未被调用 | 检查 aboutToDisappear 或暂停监听 |
| 图标显示错误 | 资源路径不对 | 确保使用 $r('app.media.xxx') |
| 模式不切换 | 未调用 PlayController | 检查点击回调绑定 |

---

## 优化建议

### 短期改进
1. 分离复用图标 (ic_scan.svg 拆分为 ic_favorite.svg + ic_download.svg)
2. 统一字体大小规范 (PlayerPage:12, Panel:11 不一致)
3. 添加加载动画 (当 isLoading=true 时)

### 中期优化
1. 提取时间/进度条为独立子组件
2. 实现播放速度调节
3. 添加音量控制 UI
4. 支持手势快进/快退

### 长期架构
1. 播放列表的搜索/排序功能
2. 播放历史记录
3. 歌词显示同步
4. 音质选择

