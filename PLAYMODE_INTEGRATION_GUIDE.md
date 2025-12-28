# 播放模式集成指南

## 问题原因

新增的3种智能播放模式（智能随机、时间感知、夜间模式）已添加到代码中，但需要**连续点击**播放模式按钮多次才能循环到它们。

**当前循环顺序（6种模式）：**
```
顺序 → 循环 → 单曲 → 智能随机 → 时间感知 → 夜间 → (回到顺序)
```

用户需要点击 3-5 次才能看到新模式！

---

## 解决方案

创建了 **PlayModeSelector** 对话框组件，用户可以直接看到并选择所有6种模式。

---

## 如何集成到现有播放器

### 方案1: 修改 PlayerControls.ets

将播放模式按钮改为打开选择器：

```typescript
import { PlayModeSelector } from '../components/PlayModeSelector'
import { PlayerViewModel } from '../viewmodel/PlayerViewModel'

@Component
export struct PlayerControls {
  @Prop playMode: PlayMode = PlayMode.SEQUENCE
  @ObjectLink playerViewModel: PlayerViewModel

  // 添加对话框控制器
  private modeSelectorDialog: CustomDialogController | null = null

  onModeClick?: () => void

  build() {
    Column() {
      Row() {
        // 播放模式 - 点击打开选择器
        Column() {
          Image(this.getModeIcon())
            .width(28)
            .height(28)
            .fillColor('#666666')

          Text(this.getModeName())
            .fontSize(10)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .onClick(() => {
          this.showModeSelector()  // ✅ 改为打开选择器
        })

        // ... 其他按钮
      }
    }
  }

  /**
   * 显示播放模式选择器
   */
  showModeSelector(): void {
    this.modeSelectorDialog = new CustomDialogController({
      builder: PlayModeSelector({
        currentMode: this.playMode,
        onModeSelected: (mode: PlayMode) => {
          // 直接设置模式，不循环
          this.playerViewModel.setPlayMode(mode)
        }
      }),
      customStyle: true,
      alignment: DialogAlignment.Bottom
    })

    this.modeSelectorDialog.open()
  }
}
```

---

### 方案2: 修改 MiniPlayer.ets

同样的方式添加到迷你播放器：

```typescript
import { PlayModeSelector } from '../components/PlayModeSelector'

@Component
export struct MiniPlayer {
  @Prop playMode: number = PlayMode.SEQUENCE
  onPlayModeClick?: () => void
  onSetPlayMode?: (mode: PlayMode) => void  // ✅ 新增回调

  private modeSelectorDialog: CustomDialogController | null = null

  build() {
    Column() {
      Row() {
        // ... 其他按钮

        // 播放模式按钮
        Column() {
          Image(this.getModeIcon())
            .width(18)
            .height(18)
            .fillColor(this.isModePressed ? '#007AFF' : '#666666')

          Text(this.getModeName())
            .fontSize(9)
            .fontColor(this.isModePressed ? '#007AFF' : '#999999')
            .margin({ top: 2 })
        }
        .margin({ left: 6 })
        .onClick(() => {
          this.showModeSelector()  // ✅ 打开选择器
        })
      }
    }
  }

  showModeSelector(): void {
    this.modeSelectorDialog = new CustomDialogController({
      builder: PlayModeSelector({
        currentMode: this.playMode as PlayMode,
        onModeSelected: (mode: PlayMode) => {
          this.onSetPlayMode?.(mode)
        }
      }),
      customStyle: true,
      alignment: DialogAlignment.Bottom
    })

    this.modeSelectorDialog.open()
  }
}
```

---

### 方案3: 保留双重功能

如果希望保留原有的循环切换功能：

```typescript
Column() {
  Image(this.getModeIcon())
    .width(28)
    .height(28)
    .fillColor('#666666')

  Text(this.getModeName())
    .fontSize(10)
    .fontColor('#999999')
    .margin({ top: 4 })
}
.gesture(
  // 单击：循环切换
  TapGesture({ count: 1 })
    .onAction(() => {
      this.playerViewModel.togglePlayMode()
    })
)
.gesture(
  // 长按：打开选择器
  LongPressGesture({ duration: 500 })
    .onAction(() => {
      this.showModeSelector()
    })
)
```

---

## 测试步骤

### 1. 运行测试页面

运行 `PlayModeSelectorDemo.ets` 查看效果：

```bash
# 将 entry/src/main/ets/pages/PlayModeSelectorDemo.ets 设为启动页
# 或在 module.json5 中添加路由
```

### 2. 验证所有模式

点击"选择播放模式"按钮，应该看到：

```
✓ 顺序播放 ▶️
✓ 列表循环 🔁
✓ 单曲循环 🔂
✓ 智能随机 🧠 [NEW]
✓ 时间感知 🕒 [NEW]
✓ 夜间模式 🌙 [NEW]
```

### 3. 确认选择功能

- 点击任意模式，对话框关闭
- Toast 提示显示新模式信息
- 当前模式标记为"使用中"

---

## UI 效果预览

### 选择器界面

```
┌─────────────────────────────────┐
│  选择播放模式              ✕     │
├─────────────────────────────────┤
│                                 │
│  ▶️  顺序播放          ✓        │
│     按照列表顺序依次播放  使用中 │
│                                 │
│  🔁  列表循环          ›        │
│     播放完列表后重新开始         │
│                                 │
│  🔂  单曲循环          ›        │
│     重复播放当前歌曲            │
│                                 │
│  🔀  随机播放          ›        │
│     随机选择歌曲播放            │
│                                 │
│  🧠  智能随机    [NEW] ›        │
│     避免同流派/专辑连续播放      │
│                                 │
│  🕒  时间感知    [NEW] ›        │
│     根据时段智能选择歌曲         │
│                                 │
│  🌙  夜间模式    [NEW] ›        │
│     舒缓音乐，音量渐弱          │
│                                 │
├─────────────────────────────────┤
│ 💡 智能模式需要歌曲元数据支持    │
└─────────────────────────────────┘
```

---

## 优势对比

| 方式 | 优点 | 缺点 |
|------|------|------|
| **循环切换** | 实现简单，不占空间 | 需要多次点击，新功能难发现 |
| **选择器面板** | 一目了然，易发现新功能 | 需要额外点击打开 |
| **双重功能** | 兼顾两种需求 | 用户需要学习两种操作 |

**推荐：** 使用**选择器面板**，配合 Toast 提示，用户体验最佳。

---

## 常见问题

### Q1: 为什么看不到新模式？

**A:** 新模式已添加到代码中，但需要：
1. 多次点击播放模式按钮循环到（4-6次）
2. 或使用 PlayModeSelector 直接选择

### Q2: 如何快速访问新模式？

**A:** 集成 PlayModeSelector 组件，用户点击模式按钮即可看到全部7种模式。

### Q3: 新模式需要什么前提？

**A:** 智能模式需要歌曲包含元数据（genre, bpm, energy, mood）：
- 扫描新歌曲时自动推断
- 或使用 MetadataEditorDialog 手动编辑

### Q4: 如何验证新模式工作？

**A:**
1. 确保歌曲有元数据
2. 选择智能模式
3. 播放并观察选歌逻辑（查看日志）

---

## 下一步

1. ✅ 集成 PlayModeSelector 到播放器
2. ✅ 添加新模式图标（可选，使用 IconResources.ets）
3. ✅ 测试所有7种模式
4. 📝 更新用户文档，说明新功能

---

## 完整示例代码

参考文件：
- `PlayModeSelector.ets` - 选择器组件
- `PlayModeSelectorDemo.ets` - 完整示例
- `PlayerViewModel.ets` - setPlayMode 方法
- `IconResources.ets` - 自定义图标（可选）
