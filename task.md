# Task List（可持续维护版）

## 维护规则

- 本文件采用追加更新（append-only）。
- 新增任务时仅追加，不覆盖或删除历史任务。
- 任务标题格式固定为：`### 任务id 日期时间(YYYY-MM-DD HH:mm) 任务等级 任务标题 完成情况`。
- 完成情况仅使用：`TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`。
- 若任务状态变化，追加一条同 ID 的新记录，保留历史状态轨迹。

## 新增任务模板

```md
### TASK-XXX YYYY-MM-DD HH:mm P1 任务标题 TODO
#### 需求描述
-

#### 实施要求
-

#### 附加信息
-

#### 验收标准
-
```

## 已完成任务

### SENTRY-001 2026-02-21 00:00 P0 实现Sentry显式开关（Hard Off） DONE
### SENTRY-002 2026-02-21 00:00 P0 移除Sentry无法关闭的强制启用路径 DONE
### SENTRY-003 2026-02-21 00:00 P1 Sentry生命周期幂等化（避免重复start/close副作用） DONE
### SENTRY-004 2026-02-21 00:00 P1 Sentry采样策略优化（分环境可灰度调参） DONE
### SENTRY-005 2026-02-21 00:00 P1 BugReport上报字段最小化与脱敏 DONE
### SENTRY-006 2026-02-21 00:00 P2 去重Home页面重复sentryTrace埋点 DONE
### SENTRY-007 2026-02-21 00:00 P2 Signposter事务管理增强（重复start防护与超时回收） DONE
### NSE-001 2026-02-21 00:00 P0 修复NSE异常路径未回调contentHandler DONE
### NSE-002 2026-02-21 00:00 P0 修复NSE并发请求下notificationHandler被覆盖 DONE
### NSE-003 2026-02-21 00:00 P1 修复NotificationHandler可能重复调用contentHandler DONE
### NSE-004 2026-02-21 00:00 P1 修复首条通知检测逻辑并发竞态 DONE
### NSE-005 2026-02-21 00:00 P1 将NSE头像占位图磁盘IO移出MainActor DONE
### ROOM-001 2026-02-21 00:00 P0 移除RoomSummary中的DispatchSemaphore阻塞async DONE
### ROOM-002 2026-02-21 00:00 P0 修复rooms跨线程读写竞争 DONE
### ROOM-003 2026-02-21 00:00 P1 限制底部可见范围触发的重复订阅任务 DONE
### HOME-001 2026-02-21 00:00 P1 减少房间列表全量重建导致的主线程卡顿 DONE
### APP-001 2026-02-21 00:00 P1 强化AppCoordinator主线程与actor隔离 DONE
### UI-001 2026-02-21 00:00 P1 提升UserIndicatorController线程安全 DONE
### SHARE-001 2026-02-21 00:00 P2 修复ShareExtension混合分享时文本媒体互斥逻辑 DONE
### SHARE-002 2026-02-21 00:00 P1 优化ShareExtension长payload经URL Scheme传递可靠性 DONE
### SHARE-003 2026-02-21 00:00 P1 修复App Group临时文件清理不完整 DONE
### CI-001 2026-02-21 00:00 P0 移除CI/发布流程中的破坏性git reset --hard DONE
### CI-002 2026-02-21 00:00 P0 修复CI对Xcode路径硬编码 DONE
### CI-003 2026-02-21 00:00 P2 setup_xcode_cloud_environment写环境变量幂等化 DONE
### CI-004 2026-02-21 00:00 P1 修复config_nightly对project.yml的持久污染 DONE
### CI-005 2026-02-21 00:00 P1 提升release_to_github对空body的容错 DONE
### CI-006 2026-02-21 00:00 P2 清理或接入未执行的Periphery配置 DONE
### PREAUTH-001 2026-02-21 00:00 P1 未登录首页新增诊断设置入口 DONE
### PREAUTH-002 2026-02-21 00:00 P1 未登录状态支持上传错误日志 DONE
### PREAUTH-003 2026-02-21 00:00 P1 在AuthenticationFlowCoordinator新增pre-auth diagnostics路由 DONE
### PREAUTH-004 2026-02-21 00:00 P1 接入pre-auth可用的sentryEnabledByUser持久化开关 DONE
### PREAUTH-005 2026-02-21 00:00 P1 绑定Sentry开关到启动切换重启路径并保证Hard Off DONE
### PREAUTH-006 2026-02-21 00:00 P1 未登录日志上传失败增加可重试提示与结果反馈 DONE
### POSTHOG-001 2026-02-21 00:00 P1 下线Analytics设置入口与Onboarding Prompt DONE
### POSTHOG-002 2026-02-21 00:00 P1 清理Analytics相关多语言文案与第三方共享声明 DONE
### POSTHOG-003 2026-02-21 00:00 P1 清理AnalyticsSettingsScreen模块残留 DONE
### POSTHOG-004 2026-02-21 00:00 P1 清理AnalyticsPromptScreen模块残留 DONE
### POSTHOG-005 2026-02-21 00:00 P1 审核并精简AnalyticsService中PostHog绑定语义注释 DONE
### POSTHOG-006 2026-02-21 00:00 P1 评估将PostHogAnalyticsClient重命名为NoopAnalyticsClient DONE
### POSTHOG-007 2026-02-21 00:00 P1 检查并移除SwiftPM或工程配置中的PostHog依赖残留 DONE
### POSTHOG-008 2026-02-21 00:00 P1 重构或删除直接依赖PostHog mock的测试 DONE
### POSTHOG-009 2026-02-21 00:00 P1 更新架构与安全文档中的PostHog描述 DONE
### TEST-001 2026-02-21 00:00 P1 去除集成与UI测试中的硬编码sleep DONE
### TEST-002 2026-02-21 00:00 P1 补充Sentry开关开关机重启联动自动化测试 DONE
### TEST-003 2026-02-21 00:00 P1 拆分并补全关键业务路径Integration Tests DONE
### TEST-004 2026-02-21 00:00 P1 扩展AccessibilityTests到真实运行流 DONE
### TEST-005 2026-02-21 00:00 P1 降低PreviewTests对固定设备系统版本硬依赖 DONE
### TEST-006 2026-02-21 00:00 P1 将测试中的fatalError失败模式改为XCTFail DONE
### DOC-001 2026-02-21 00:00 P2 同步文档与架构说明到当前实现状态 DONE

## 待办任务

### CRASH-001 2026-02-21 18:00 P0 修复LoginScreenViewModel用户名分割数组越界 TODO
#### 需求描述
- `LoginScreenViewModel.swift:74` 中 `username.split(separator: ":")[1]` 无边界检查，当用户名不含 `:` 时直接崩溃。

#### 实施要求
- 使用 `guard components.count > 1` 安全访问分割结果。
- 补充单元测试覆盖无 `:` 和空字符串场景。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：登录流程，用户输入触发。

#### 验收标准
- 输入不含 `:` 的用户名不再崩溃，走错误提示路径。
- 新增对应单元测试。

### CRASH-002 2026-02-21 18:00 P0 修复MXLog路径组件数组越界 TODO
#### 需求描述
- `MXLog.swift:98` 中 `URL.documentsDirectory.pathComponents[2]` 假设路径至少3层，在特殊环境下可能越界崩溃。

#### 实施要求
- 使用安全下标或 guard 检查 `pathComponents.count > 2`，提供默认值 `"UNKNOWN"`。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：所有 Debug 日志路径。

#### 验收标准
- 路径组件不足时不崩溃，使用默认值。

### CRASH-003 2026-02-21 18:00 P0 修复TypingIndicatorView成员数组越界竞态 TODO
#### 需求描述
- `TypingIndicatorView.swift:37-49` 中 switch 检查 count 后直接访问 `members[0]`/`members[1]`，但 members 可能在检查与访问之间被修改（竞态）。

#### 实施要求
- 在 switch 前复制一份 members 快照，对快照进行安全下标访问。
- 或使用 `guard members.count >= N` 在每个 case 内再次校验。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：聊天界面正在输入指示器。

#### 验收标准
- 并发修改 members 时不崩溃。

### CRASH-004 2026-02-21 18:00 P0 修复RoomSummaryProvider popFront空数组崩溃 TODO
#### 需求描述
- `RoomSummaryProvider.swift:356` 中 `case .popFront` 直接访问 `rooms[0]`，无空数组保护。

#### 实施要求
- 添加 `guard !rooms.isEmpty else { break }` 保护。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：房间列表差量更新。

#### 验收标准
- 空 rooms 时 popFront 不崩溃，安全跳过。

### CRASH-005 2026-02-21 18:00 P0 修复AuthenticationService accountProviders空数组崩溃 TODO
#### 需求描述
- `AuthenticationService.swift:43,213` 中 `accountProviders[0]` 无空检查，当配置为空时启动即崩溃。

#### 实施要求
- 添加 `guard !appSettings.accountProviders.isEmpty` 保护，提供合理的默认值或错误提示。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：认证服务初始化，启动路径。

#### 验收标准
- accountProviders 为空时不崩溃，记录错误日志。

### CRASH-006 2026-02-21 18:00 P0 将AppCoordinator中7处fatalError替换为安全降级 TODO
#### 需求描述
- `AppCoordinator.swift:614,633,677,732,820,875,999` 中7处 `fatalError("User session not setup")` 会在 userSession 为 nil 时直接崩溃。

#### 实施要求
- 替换为 `guard let userSession else { MXLog.error(...); return }` 模式。
- 状态机转换中的 fatalError（:560,:568）替换为 `MXLog.error` + 安全回退状态。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：AppCoordinator 全局，涉及多个用户流程。

#### 验收标准
- 所有生产代码路径中的 fatalError 被替换，异常状态记录日志并安全降级。

### RACE-001 2026-02-21 18:00 P0 修复MXLog nonisolated(unsafe)静态变量数据竞争 TODO
#### 需求描述
- `MXLog.swift:16-17` 中 `rootSpan` 和 `currentTarget` 标记为 `nonisolated(unsafe)`，多线程并发读写无同步保护。

#### 实施要求
- 使用 `NSLock` 或 `os_unfair_lock` 保护静态变量访问。
- 或重构为线程安全的初始化模式（dispatch_once / actor）。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：全局日志系统，所有线程。

#### 验收标准
- 多线程并发调用 MXLog 不产生数据竞争（TSan 验证）。

### RACE-002 2026-02-21 18:00 P0 修复NSE targetConfiguration静态变量竞态 TODO
#### 需求描述
- `NotificationServiceExtension.swift:35` 中 `targetConfiguration` 静态变量在 init 写入、handle 读取，并发通知到达时存在竞态。

#### 实施要求
- 使用 `NSLock` 保护 `targetConfiguration` 的读写，与已有的 `firstNotificationLock` 模式一致。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：NSE 并发通知处理。

#### 验收标准
- 并发 didReceive 调用不产生数据竞争。

### RACE-003 2026-02-21 18:00 P0 修复ExpiringTaskRunner continuation Actor隔离违规 TODO
#### 需求描述
- `ExpiringTaskRunner.swift:15-45` 中 `continuation` 属性在两个独立 Task 中并发读写，虽然类型为 actor 但 Task 可能不在 actor 隔离域内执行。
- `CheckedContinuation` 不是 `Sendable`，跨 actor 传递违反隔离规则。

#### 实施要求
- 确保两个 Task 使用 `Task { await self.xxx() }` 保持 actor 隔离。
- 或重构为单一 Task + `withTaskGroup` 模式管理超时和执行。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：所有使用 ExpiringTaskRunner 的超时逻辑。

#### 验收标准
- Actor 隔离正确，TSan 无告警。

### THREAD-001 2026-02-21 18:00 P1 修复ClientProxy后台线程Combine Subject.send线程安全 TODO
#### 需求描述
- `ClientProxy.swift` 多处 SDK listener 回调在后台线程直接调用 `subject.send()`，Combine Subject 非线程安全。

#### 实施要求
- 所有 `.send()` 调用包装在 `DispatchQueue.main.async` 中，或将 Subject 操作移至 `@MainActor` 隔离函数。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：ClientProxy 中所有 Subject（ignoredUsers、verificationState、sendQueueStatus 等）。

#### 验收标准
- 所有 Subject.send() 在主线程执行。

### THREAD-002 2026-02-21 18:00 P1 修复Combine sink缺少.receive(on: .main) TODO
#### 需求描述
- `RoomDirectorySearchProxy.swift:41` 等多处 sink 回调未指定接收线程，上游后台线程发布时会在非主线程执行 UI 相关操作。

#### 实施要求
- 审查所有 sink 闭包中涉及 UI 状态更新的订阅链，添加 `.receive(on: DispatchQueue.main)`。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：RoomDirectorySearchProxy、HomeScreenViewModel 等。

#### 验收标准
- 所有 UI 状态更新在主线程执行。

### THREAD-003 2026-02-21 18:00 P1 修复HomeScreenViewModel火和忘Task生命周期泄漏 TODO
#### 需求描述
- `HomeScreenViewModel.swift:106-108,142,164-176` 等多处创建 `Task { }` 未保存引用，ViewModel 销毁后 Task 仍在执行。

#### 实施要求
- 将 Task 存储在实例属性中，在 deinit 或页面消失时取消。
- 或使用 `@CancellableTask` 属性包装器。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：HomeScreenViewModel 及类似模式的其他 ViewModel。

#### 验收标准
- ViewModel 销毁后不再有孤立 Task 执行。

### THREAD-004 2026-02-21 18:00 P1 修复UserIndicatorController delayedIndicators Set竞态 TODO
#### 需求描述
- `UserIndicatorController.swift:52-60` 中 `delayedIndicators` Set 在 `submitIndicator` 和延迟 Task 闭包中并发访问，无同步保护。

#### 实施要求
- 使用 `@MainActor` 隔离或 NSLock 保护 Set 的读写操作。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：全局 UserIndicator 系统。

#### 验收标准
- 并发提交 indicator 不产生 Set 数据竞争。

### LEAK-001 2026-02-21 18:00 P1 修复TimelineTableViewController通知观察者泄漏 TODO
#### 需求描述
- `TimelineTableViewController.swift:320-323` 中 `NotificationCenter.default.addObserver(self, ...)` 添加的 `reduceMotionStatusDidChangeNotification` 观察者从未在 deinit 移除。

#### 实施要求
- 在 deinit 中添加 `NotificationCenter.default.removeObserver(self)` 清理。
- 或改用 Combine `.publisher(for:)` 模式自动管理生命周期。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：切换房间时 TimelineTableViewController 泄漏。

#### 验收标准
- deinit 中移除所有通知观察者，Instruments 验证无泄漏。

### CRASH-007 2026-02-21 18:00 P1 修复BlurHashEncode force unwrap崩溃风险 TODO
#### 需求描述
- `BlurHashEncode.swift:69` 中 `factors.first!` 和 `:79` 中 `.max()!` 强制解包，空集合时崩溃。

#### 实施要求
- 替换为 `guard let dc = factors.first else { return nil }` 和 `.max() ?? 0`。

#### 附加信息
- 来源：2026-02-21 工程审计。

#### 验收标准
- 空输入时安全返回 nil，不崩溃。

### CRASH-008 2026-02-21 18:00 P1 修复MapLibreMapView @unknown default fatalError TODO
#### 需求描述
- `MapLibreMapView.swift:233` 中 `@unknown default: fatalError()` 在未来 iOS 新增 ColorScheme 枚举值时会崩溃。

#### 实施要求
- 替换为 `@unknown default: self = .light; MXLog.warning("Unknown ColorScheme")` 安全回退。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：地图功能，未来 iOS 兼容性。

#### 验收标准
- 新增 ColorScheme 值时不崩溃，回退到 light 模式。

### CRASH-009 2026-02-21 18:00 P1 修复AppCoordinator版本解析fatalError TODO
#### 需求描述
- `AppCoordinator.swift:143` 中 `guard let currentVersion = Version(...) else { fatalError() }` 在版本号格式异常时启动即崩溃。

#### 实施要求
- 替换为 `guard ... else { MXLog.error(...); return }` 或使用默认版本号 `Version(0,0,0)` 降级。

#### 附加信息
- 来源：2026-02-21 工程审计。
- 影响范围：应用启动路径。

#### 验收标准
- 版本号解析失败时不崩溃，记录错误日志。

### SEC-001 2026-02-21 18:00 P1 将硬编码凭证迁移到安全配置 TODO
#### 需求描述
- `AppSettings.swift:298-301` Sentry DSN 包含嵌入式认证令牌明文写在源码中。
- `AppSettings.swift:360` MapTiler API Key 硬编码。
- 这些凭证已随源码提交，需视为已泄露。

#### 实施要求
- 将 Sentry DSN 和 MapTiler API Key 迁移到 xcconfig 文件（不纳入版本控制）或 Xcode Cloud Secrets。
- 在 CI/CD 中通过环境变量注入。
- 轮换所有已暴露的凭证。
- 添加 CI 扫描规则防止再次提交明文密钥。

#### 附加信息
- 来源：2026-02-21 安全审计。
- 严重级别：CRITICAL。

#### 验收标准
- 源码中无硬编码凭证，凭证通过安全渠道注入。
- 旧凭证已轮换。

### SEC-002 2026-02-21 18:00 P1 实现Recovery Key剪贴板自动过期 TODO
#### 需求描述
- `SecureBackupRecoveryKeyScreenViewModel.swift:55` 中恢复密钥复制到剪贴板后永不过期，恶意应用可读取。

#### 实施要求
- 复制后120秒自动清除剪贴板（仅当内容未被用户修改时）。
- 添加用户提示："恢复密钥将在2分钟后从剪贴板移除"。

#### 附加信息
- 来源：2026-02-21 安全审计。

#### 验收标准
- 复制恢复密钥后120秒自动清除，剪贴板内容被替换时不误清。

### SEC-003 2026-02-21 18:00 P1 为敏感文件添加Complete文件保护属性 TODO
#### 需求描述
- 目前仅 `VoiceMessageCache.swift` 设置了 `.complete` 文件保护，其他临时文件、缓存文件缺失保护。

#### 实施要求
- 审查所有 FileManager 写入操作，对包含用户内容或敏感数据的文件添加 `URLFileProtection.complete`。
- 创建统一工具函数 `setCompleteFileProtection(url:)` 复用。

#### 附加信息
- 来源：2026-02-21 安全审计。

#### 验收标准
- 所有敏感文件写入后具有 `.complete` 保护属性。

### SEC-004 2026-02-21 18:00 P2 为敏感页面添加截屏保护 TODO
#### 需求描述
- SecureBackup 恢复密钥页面、PIN 输入页面、认证页面无截屏保护。

#### 实施要求
- 在敏感页面使用 `UITextField.isSecureTextEntry` 技巧或 `UIScreen.capturedDidChangeNotification` 监听实现截屏保护。
- 或在页面激活时显示隐私遮罩。

#### 附加信息
- 来源：2026-02-21 安全审计。

#### 验收标准
- 截屏/录屏时敏感页面内容被遮挡或模糊。

### PERF-001 2026-02-21 18:00 P2 为ForEach添加稳定.id()消除列表抖动 TODO
#### 需求描述
- `HomeScreenRoomList.swift`、`HomeScreenContent.swift`、`EmojiPickerScreen.swift` 等8+处 ForEach 缺少显式 `.id()`，导致列表重排时UI抖动（GitHub #2386, #3026）。
- `HomeScreenContent.swift:88-98` 中的滚动 workaround 是症状修补。

#### 实施要求
- 为所有 ForEach 添加 `.id(\.roomID)` 等稳定标识符。
- 验证抖动问题修复后移除滚动 workaround。

#### 附加信息
- 来源：2026-02-21 架构审计。

#### 验收标准
- 房间列表滚动无抖动，workaround 代码移除。

### PERF-002 2026-02-21 18:00 P2 拆分TimelineViewModel降低复杂度 TODO
#### 需求描述
- `TimelineViewModel.swift` 共1072行，管理 timeline 构建、分页、消息发送、反应、已读回执、音频播放等多个关注点。

#### 实施要求
- 提取 `TimelineItemBuilder` 处理 timeline 构建与分组。
- 提取 `TimelinePaginationManager` 处理前向/后向分页。
- 扩展已有 `TimelineInteractionHandler` 覆盖更多交互逻辑。

#### 附加信息
- 来源：2026-02-21 架构审计。
- SwiftLint 规则：函数体不超过100行。

#### 验收标准
- TimelineViewModel 行数降至500行以下，各组件职责清晰。

### PERF-003 2026-02-21 18:00 P2 合并HomeScreenContent中重复的updateVisibleRange触发 TODO
#### 需求描述
- `HomeScreenContent.swift:66-74` 中 `updateVisibleRange()` 被 `didScroll`、`isScrolling`、`onChange(searchQuery)`、`onChange(visibleRooms)` 四个事件重复触发。

#### 实施要求
- 合并滚动事件为单一订阅。
- 添加 `.debounce(for: .milliseconds(100))` 防抖。

#### 附加信息
- 来源：2026-02-21 架构审计。

#### 验收标准
- 单次滚动操作仅触发一次 updateVisibleRange。

### PERF-004 2026-02-21 18:00 P2 将DispatchQueue.main.asyncAfter迁移为Task.sleep结构化并发 TODO
#### 需求描述
- 全项目16处使用 `DispatchQueue.main.asyncAfter`，破坏结构化并发、无法取消、难以推理执行顺序。

#### 实施要求
- 替换为 `Task { try await Task.sleep(for: .milliseconds(N)); ... }` 模式。
- 确保替换后的 Task 被正确存储和取消。

#### 附加信息
- 来源：2026-02-21 架构审计。
- 涉及文件：HomeScreenViewModel、RoomScreenViewModel、TimelineItemMenu 等。

#### 验收标准
- 项目中不再有 `DispatchQueue.main.asyncAfter` 调用（SwiftLint 规则可选）。

### PERF-005 2026-02-21 18:00 P2 修复OverridableAvatarImage绕过Kingfisher缓存 TODO
#### 需求描述
- `OverridableAvatarImage.swift:23` 使用 SwiftUI 原生 `AsyncImage` 而非项目统一的 `LoadableImage`（Kingfisher），导致缓存策略不一致、可能重复下载。

#### 实施要求
- 替换 `AsyncImage` 为 `LoadableImage`，保持全项目缓存策略一致。

#### 附加信息
- 来源：2026-02-21 架构审计。

#### 验收标准
- 头像加载走 Kingfisher 统一缓存。

### CRASH-010 2026-02-21 18:00 P1 修复RoomDirectorySearchProxy数组越界 TODO
#### 需求描述
- `RoomDirectorySearchProxy.swift:110,119` 中 `case .popFront` 和 `case .remove(index)` 直接数组下标访问无边界检查。

#### 实施要求
- 添加 `guard !results.isEmpty` 和 `guard Int(index) < results.count` 保护。

#### 附加信息
- 来源：2026-02-21 工程审计。

#### 验收标准
- 空数组或越界 index 不崩溃。

### CRASH-011 2026-02-21 18:00 P2 修复RoomAvatarImage空用户数组防护 TODO
#### 需求描述
- `RoomAvatarImage.swift:77-110` 中条件分支访问 `users[0]`/`users[1]` 前虽有 count 检查，但缺少空数组兜底。

#### 实施要求
- 添加 `guard !users.isEmpty else { return PlaceholderAvatarImage(...) }` 前置保护。

#### 附加信息
- 来源：2026-02-21 工程审计。

#### 验收标准
- 空 users 数组时显示占位头像，不崩溃。
