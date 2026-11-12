# WXRefresh

**仿微信朋友圈的下拉刷新**，Objective-C，一个 UIView 分类搞定。

和常见的下拉刷新控件不一样：刷新图标不在列表顶部占位，而是**跟着你手指从导航栏位置往下滑**，滑过临界点松手就开始刷新，松手位置不够就弹回去。整套交互照微信朋友圈做的。

## 特点

- **零侵入**：全部通过 `UIView` 分类 + `objc_setAssociatedObject` 实现，不改你的 ViewController、不给 UIScrollView 加子类、不写 headerView
- **一个方法接入**：`sw_refreshWithObject:atPoint:downRefresh:`，一行代码挂上
- **跟随手势的图标**：下拉过程中图标实时跟手移动，不是"到点弹出来"
- **三态机**：非刷新 / 刷新中 / 全屏蔽，第三个状态专门用来挡掉系统进界面时的自动下拉
- **iPhone X 适配**：刘海屏把图标可下移区间从 130 调整到 150

## 快速使用

```objc
#import "UIView+SWRefresh.h"

// 1. 挂上刷新（一般写在 viewDidLoad）
__weak typeof(self) wself = self;
[self.view sw_refreshWithObject:self.tableView
                        atPoint:CGPointMake(30.f, -70.f)
                    downRefresh:^{
                        [wself requestData];
                    }];

// 2. 进页面先主动刷一次
[self.view beginRefresh];
```

数据回来了，调一次结束：

```objc
[self.view sw_endRefresh];
```

离开页面记得释放 KVO：

```objc
- (void)dealloc {
    [self.view sw_freeReFresh];
}
```

> `sw_freeReFresh` 是必须的。内部用 KVO 监听 `contentOffset`，不注销就移除监听对象，会直接崩在 `observeValueForKeyPath:`。

## API

| 方法 | 说明 |
| --- | --- |
| `sw_refreshWithObject:atPoint:downRefresh:` | 挂上刷新。`scrollView` 是要监听的列表，`position` 是图标初始位置（默认 `{10, 34}`，即导航栏左上角），`block` 是触发刷新的回调 |
| `beginRefresh` | 主动进入刷新态，适合首次进入页面自动加载 |
| `sw_endRefresh` | 结束刷新，图标回弹到顶部并转回原位 |
| `sw_freeReFresh` | 注销 KVO，**dealloc 里必须调** |

`atPoint` 传 `CGPointMake(30.f, -70.f)` 的 Demo 写法里，x 会被内部强制改成 15，实际生效的主要是 y —— 想调图标高度就改 y。

## 三个状态

```objc
typedef NS_ENUM(NSInteger, StatusOfRefresh) {
    SWREFRESH_Default = 1,     // 非刷新状态（注意不能为 0）
    SWREFRESH_BeginRefresh,    // 刷新中
    SWREFRESH_None             // 全屏蔽，任何下拉动作都不响应
};
```

`SWREFRESH_None` 是这套代码里最实用的一处设计：进入带 `contentInset` 的页面时，系统会自己把列表下拉一截，如果不屏蔽，图标会莫名往下蹿一下。置成 `None` 期间不处理任何 offset 变化，等页面稳定了再切回 `Default`。

另外代码里还有一段 `dispatch_after 0.1s` 的延迟初始化，专门用来吃掉"进入界面时的第一次系统下拉"。0.1 秒是手调出来的经验值。

## 它是怎么工作的

```
KVO 监听 contentOffset
      ↓
offsetY + contentInset.top = 相对顶部的真实下拉距离
      ↓
├─ 没到临界点 → 图标跟着手指走（refreshView.contentOffset = 距离）
├─ 到临界点但还按着 → 图标停在最大位置
├─ 到临界点且已松手 → 进入刷新态，图标开始转圈，触发 block
└─ 回到顶部 → 图标归零，转角复位
```

临界点就是 `threshold`，值等于 `-MARGINTOP`（iPhone X 上是 `-150`，其他是 `-130`），也就是"往下拉 130~150pt 才算数"。

`contentInset.top` 是实时同步的 —— 系统会自动改它（比如 `automaticallyAdjustsScrollViewInsets`），你自己也会改它（比如给列表留出 tabbar 空间）。代码里每次 KVO 回调都对一次，所以不会因为 inset 变了导致临界点漂移。

## 集成

### 方式一：拖源码（推荐）

把 `WXRefresh/` 下的 `UIView+SWRefresh.h` 和 `.m` 拖进工程，就这两个文件，没有任何第三方依赖。

### 方式二：CocoaPods

`WXRefresh.podspec` 已声明 `s.platform = :ios, "7.0"`，但**没有发布到官方源**，需要走本地路径：

```ruby
pod 'WXRefresh', :path => '../WXRefresh'
```

## Demo

`WXRefreshDemo/WXRefreshDemo.xcodeproj`，直接打开跑。接法在 `FirstViewController.m` 第 53 行左右。

Demo 里列表是 `self.tableView`，但分类挂在 `self.view` 上——这两者不是同一个对象，代码内部靠 `extenScrollView` 关联对象把二者接上，所以不会互相干扰。

## 可调常量

都在 `UIView+SWRefresh.m` 顶部：

| 常量 | 值 | 作用 |
| --- | --- | --- |
| `MARGINTOP` | iPhone X `150` / 其他 `130` | 图标可下移的最大区间，也是触发刷新的临界距离 |
| `ICONSIZE` | `22` | 图标边长 |
| `CircleTime` | `0.5` | 刷新时转一圈的时长（秒） |
| `IconBackTime` | `0.2` | 结束后图标回弹时长（秒） |

## 已知限制

- 只能做**下拉刷新**，没有上拉加载更多。
- 图标是一张固定的图（`RefreshView` 里的 `refreshIcon`），没有换图/换动画的接口。
- 内部有一处 `dispatch_async` 套 `dispatch_async` 回主线程的写法（`observeValueForKeyPath:` 里），功能上没问题，属于可优化的冗余。
- 依赖 `contentInset` 的行为，如果你的列表用了自定义的 `contentInsetAdjustmentBehavior`，临界点需要重新调。

## License

MIT
