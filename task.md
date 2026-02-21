# GIM iOS — 任务清单

> 更新日期: 2026-02-22 00:30

## 使用规范

### 任务格式

- [ ] **PREFIX-001 简短祈使句标题** `P1`
  - description: 需要做什么，包含上下文和验收标准
  - activeForm: 进行中时的现在进行时描述（用于 spinner 显示）
  - createdAt: YYYY-MM-DD HH:mm
  - blocked by: 依赖的前置任务（可选）
  - blocks: 被本任务阻塞的后续任务（可选）
  - owner: 负责人/agent 名称（可选）

### 任务编号

- 格式：`前缀-序号`，前缀为大写类别缩写，序号三位补零。
- 示例：`AUTH-001`、`UI-002`、`API-003`、`BUG-001`、`PERF-001`。
- 编号一旦分配不可复用或重编。

### 状态标记

| 标记 | 含义 |
|------|------|
| `[ ]` | 待办 |
| `[-]` | 进行中 |
| `[x]` | 已完成 |
| `[~]` | 关闭/不做 |

### 优先级

| 标签 | 含义 |
|------|------|
| `P0` | 阻塞性问题，立即处理 |
| `P1` | 高优先级，当前迭代 |
| `P2` | 中优先级，下次迭代 |
| `P3` | 低优先级，待规划 |

### 更新规则

- **仅更新复选框标记**（如 `[ ]` → `[x]`）；**禁止删除描述、子字段或任何其他信息**。
- 原地更新状态标记，不在分区之间移动任务。
- 已完成任务：标记改为 `[x]`，保留所有子字段不变。
- 关闭任务：标记改为 `[~]`，如需要可在 description 中添加一行关闭原因，保留所有现有子字段。
- 新任务追加到列表末尾。

---

## 任务

- [x] **SENTRY-001 实现Sentry显式开关（Hard Off）** `P0`
  - description: 实现用户可控的Sentry开关，确保关闭时完全不发送数据
  - activeForm: 实现Sentry显式开关中
  - createdAt: 2026-02-21 00:00

- [x] **SENTRY-002 移除Sentry无法关闭的强制启用路径** `P0`
  - description: 移除代码中绕过用户设置强制启用Sentry的逻辑
  - activeForm: 移除Sentry强制启用路径中
  - createdAt: 2026-02-21 00:00

- [x] **SENTRY-003 Sentry生命周期幂等化（避免重复start/close副作用）** `P1`
  - description: 确保Sentry的start/close操作幂等，避免重复调用导致副作用
  - activeForm: 幂等化Sentry生命周期中
  - createdAt: 2026-02-21 00:00

- [x] **SENTRY-004 Sentry采样策略优化（分环境可灰度调参）** `P1`
  - description: 按环境配置不同的采样率，支持灰度调整
  - activeForm: 优化Sentry采样策略中
  - createdAt: 2026-02-21 00:00

- [x] **SENTRY-005 BugReport上报字段最小化与脱敏** `P1`
  - description: 精简BugReport上报字段，对敏感信息脱敏处理
  - activeForm: 最小化BugReport上报字段中
  - createdAt: 2026-02-21 00:00

- [x] **SENTRY-006 去重Home页面重复sentryTrace埋点** `P2`
  - description: 清理Home页面中重复的Sentry trace埋点
  - activeForm: 去重sentryTrace埋点中
  - createdAt: 2026-02-21 00:00

- [x] **SENTRY-007 Signposter事务管理增强（重复start防护与超时回收）** `P2`
  - description: 增强Signposter事务管理，防止重复start并添加超时回收机制
  - activeForm: 增强Signposter事务管理中
  - createdAt: 2026-02-21 00:00

- [x] **NSE-001 修复NSE异常路径未回调contentHandler** `P0`
  - description: 修复Notification Service Extension异常路径下未调用contentHandler导致通知丢失
  - activeForm: 修复NSE contentHandler回调中
  - createdAt: 2026-02-21 00:00

- [x] **NSE-002 修复NSE并发请求下notificationHandler被覆盖** `P0`
  - description: 修复并发通知请求时notificationHandler被后续请求覆盖的问题
  - activeForm: 修复NSE并发覆盖问题中
  - createdAt: 2026-02-21 00:00

- [x] **NSE-003 修复NotificationHandler可能重复调用contentHandler** `P1`
  - description: 防止contentHandler被多次调用导致崩溃
  - activeForm: 修复contentHandler重复调用中
  - createdAt: 2026-02-21 00:00

- [x] **NSE-004 修复首条通知检测逻辑并发竞态** `P1`
  - description: 修复首条通知检测在并发场景下的竞态条件
  - activeForm: 修复通知检测竞态中
  - createdAt: 2026-02-21 00:00

- [x] **NSE-005 将NSE头像占位图磁盘IO移出MainActor** `P1`
  - description: 将头像占位图的磁盘读写操作从主线程移到后台
  - activeForm: 迁移NSE磁盘IO中
  - createdAt: 2026-02-21 00:00

- [x] **ROOM-001 移除RoomSummary中的DispatchSemaphore阻塞async** `P0`
  - description: 移除在async上下文中使用DispatchSemaphore导致的死锁风险
  - activeForm: 移除DispatchSemaphore中
  - createdAt: 2026-02-21 00:00

- [x] **ROOM-002 修复rooms跨线程读写竞争** `P0`
  - description: 修复rooms集合在多线程环境下的读写竞争问题
  - activeForm: 修复rooms竞争条件中
  - createdAt: 2026-02-21 00:00

- [x] **ROOM-003 限制底部可见范围触发的重复订阅任务** `P1`
  - description: 限制滚动到底部时重复触发的订阅任务，避免性能浪费
  - activeForm: 限制重复订阅任务中
  - createdAt: 2026-02-21 00:00

- [x] **HOME-001 减少房间列表全量重建导致的主线程卡顿** `P1`
  - description: 优化房间列表更新策略，避免全量重建引起的UI卡顿
  - activeForm: 优化房间列表重建中
  - createdAt: 2026-02-21 00:00

- [x] **APP-001 强化AppCoordinator主线程与actor隔离** `P1`
  - description: 确保AppCoordinator正确隔离主线程和actor操作
  - activeForm: 强化AppCoordinator线程隔离中
  - createdAt: 2026-02-21 00:00

- [x] **UI-001 提升UserIndicatorController线程安全** `P1`
  - description: 修复UserIndicatorController的线程安全问题
  - activeForm: 提升UserIndicatorController线程安全中
  - createdAt: 2026-02-21 00:00

- [x] **SHARE-001 修复ShareExtension混合分享时文本媒体互斥逻辑** `P2`
  - description: 修复同时分享文本和媒体时的互斥逻辑错误
  - activeForm: 修复ShareExtension混合分享中
  - createdAt: 2026-02-21 00:00

- [x] **SHARE-002 优化ShareExtension长payload经URL Scheme传递可靠性** `P1`
  - description: 优化大数据量通过URL Scheme传递的可靠性
  - activeForm: 优化ShareExtension payload传递中
  - createdAt: 2026-02-21 00:00

- [x] **SHARE-003 修复App Group临时文件清理不完整** `P1`
  - description: 确保App Group中的临时文件被完整清理
  - activeForm: 修复临时文件清理中
  - createdAt: 2026-02-21 00:00

- [x] **CI-001 移除CI/发布流程中的破坏性git reset --hard** `P0`
  - description: 移除CI脚本中危险的git reset --hard操作
  - activeForm: 移除CI破坏性操作中
  - createdAt: 2026-02-21 00:00

- [x] **CI-002 修复CI对Xcode路径硬编码** `P0`
  - description: 修复CI脚本中Xcode路径的硬编码问题
  - activeForm: 修复CI Xcode路径中
  - createdAt: 2026-02-21 00:00

- [x] **CI-003 setup_xcode_cloud_environment写环境变量幂等化** `P2`
  - description: 确保Xcode Cloud环境变量设置操作幂等
  - activeForm: 幂等化CI环境变量中
  - createdAt: 2026-02-21 00:00

- [x] **CI-004 修复config_nightly对project.yml的持久污染** `P1`
  - description: 修复nightly构建配置对project.yml的持久性修改
  - activeForm: 修复config_nightly污染中
  - createdAt: 2026-02-21 00:00

- [x] **CI-005 提升release_to_github对空body的容错** `P1`
  - description: 增强release_to_github在body为空时的容错处理
  - activeForm: 提升release容错能力中
  - createdAt: 2026-02-21 00:00

- [x] **CI-006 清理或接入未执行的Periphery配置** `P2`
  - description: 清理或正确接入未被执行的Periphery死代码检测配置
  - activeForm: 清理Periphery配置中
  - createdAt: 2026-02-21 00:00

- [x] **PREAUTH-001 未登录首页新增诊断设置入口** `P1`
  - description: 在未登录状态的首页添加诊断设置入口
  - activeForm: 新增诊断设置入口中
  - createdAt: 2026-02-21 00:00

- [x] **PREAUTH-002 未登录状态支持上传错误日志** `P1`
  - description: 允许用户在未登录状态下上传错误日志
  - activeForm: 实现未登录日志上传中
  - createdAt: 2026-02-21 00:00

- [x] **PREAUTH-003 在AuthenticationFlowCoordinator新增pre-auth diagnostics路由** `P1`
  - description: 在认证流程中添加pre-auth诊断页面的路由
  - activeForm: 新增diagnostics路由中
  - createdAt: 2026-02-21 00:00

- [x] **PREAUTH-004 接入pre-auth可用的sentryEnabledByUser持久化开关** `P1`
  - description: 实现pre-auth阶段可用的Sentry用户开关持久化
  - activeForm: 接入Sentry持久化开关中
  - createdAt: 2026-02-21 00:00

- [x] **PREAUTH-005 绑定Sentry开关到启动切换重启路径并保证Hard Off** `P1`
  - description: 将Sentry开关绑定到启动流程，确保切换后重启并保证Hard Off生效
  - activeForm: 绑定Sentry启动开关中
  - createdAt: 2026-02-21 00:00

- [x] **PREAUTH-006 未登录日志上传失败增加可重试提示与结果反馈** `P1`
  - description: 日志上传失败时提供重试选项和结果反馈
  - activeForm: 增加日志上传重试反馈中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-001 下线Analytics设置入口与Onboarding Prompt** `P1`
  - description: 移除Analytics设置入口和新用户引导中的Analytics提示
  - activeForm: 下线Analytics设置入口中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-002 清理Analytics相关多语言文案与第三方共享声明** `P1`
  - description: 清理Analytics相关的翻译文案和第三方数据共享声明
  - activeForm: 清理Analytics文案中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-003 清理AnalyticsSettingsScreen模块残留** `P1`
  - description: 移除AnalyticsSettingsScreen相关的所有残留代码
  - activeForm: 清理AnalyticsSettingsScreen中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-004 清理AnalyticsPromptScreen模块残留** `P1`
  - description: 移除AnalyticsPromptScreen相关的所有残留代码
  - activeForm: 清理AnalyticsPromptScreen中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-005 审核并精简AnalyticsService中PostHog绑定语义注释** `P1`
  - description: 审核AnalyticsService中与PostHog相关的注释，精简过时内容
  - activeForm: 精简PostHog注释中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-006 评估将PostHogAnalyticsClient重命名为NoopAnalyticsClient** `P1`
  - description: 评估并执行将PostHogAnalyticsClient重命名为NoopAnalyticsClient
  - activeForm: 评估重命名AnalyticsClient中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-007 检查并移除SwiftPM或工程配置中的PostHog依赖残留** `P1`
  - description: 检查并清理SwiftPM和工程配置中PostHog相关的依赖
  - activeForm: 检查PostHog依赖残留中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-008 重构或删除直接依赖PostHog mock的测试** `P1`
  - description: 重构或删除直接依赖PostHog mock的测试用例
  - activeForm: 重构PostHog测试中
  - createdAt: 2026-02-21 00:00

- [x] **POSTHOG-009 更新架构与安全文档中的PostHog描述** `P1`
  - description: 更新文档中关于PostHog的描述以反映当前状态
  - activeForm: 更新PostHog文档中
  - createdAt: 2026-02-21 00:00

- [x] **TEST-001 去除集成与UI测试中的硬编码sleep** `P1`
  - description: 将测试中的硬编码sleep替换为适当的等待机制
  - activeForm: 去除硬编码sleep中
  - createdAt: 2026-02-21 00:00

- [x] **TEST-002 补充Sentry开关开关机重启联动自动化测试** `P1`
  - description: 添加Sentry开关切换与重启联动的自动化测试
  - activeForm: 补充Sentry开关测试中
  - createdAt: 2026-02-21 00:00

- [x] **TEST-003 拆分并补全关键业务路径Integration Tests** `P1`
  - description: 拆分并完善关键业务路径的集成测试
  - activeForm: 补全集成测试中
  - createdAt: 2026-02-21 00:00

- [x] **TEST-004 扩展AccessibilityTests到真实运行流** `P1`
  - description: 将无障碍测试扩展到覆盖真实使用流程
  - activeForm: 扩展无障碍测试中
  - createdAt: 2026-02-21 00:00

- [x] **TEST-005 降低PreviewTests对固定设备系统版本硬依赖** `P1`
  - description: 降低预览测试对特定设备和系统版本的依赖
  - activeForm: 降低PreviewTests硬依赖中
  - createdAt: 2026-02-21 00:00

- [x] **TEST-006 将测试中的fatalError失败模式改为XCTFail** `P1`
  - description: 将测试中使用fatalError的失败模式替换为XCTFail
  - activeForm: 替换fatalError为XCTFail中
  - createdAt: 2026-02-21 00:00

- [x] **DOC-001 同步文档与架构说明到当前实现状态** `P2`
  - description: 更新文档和架构说明以反映当前代码实现
  - activeForm: 同步文档中
  - createdAt: 2026-02-21 00:00

- [x] **CRASH-001 修复LoginScreenViewModel用户名分割数组越界** `P0`
  - description: 修复用户名分割时的数组越界崩溃
  - activeForm: 修复用户名分割越界中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-002 修复MXLog路径组件数组越界** `P0`
  - description: 修复MXLog中路径组件的数组越界崩溃
  - activeForm: 修复MXLog越界中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-003 修复TypingIndicatorView成员数组越界竞态** `P0`
  - description: 修复TypingIndicatorView中成员数组的越界竞态条件
  - activeForm: 修复TypingIndicator越界中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-004 修复RoomSummaryProvider popFront空数组崩溃** `P0`
  - description: 修复popFront在空数组上调用导致的崩溃
  - activeForm: 修复popFront崩溃中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-005 修复AuthenticationService accountProviders空数组崩溃** `P0`
  - description: 修复accountProviders为空时的数组越界崩溃
  - activeForm: 修复accountProviders崩溃中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-006 将AppCoordinator中7处fatalError替换为安全降级** `P0`
  - description: 将AppCoordinator中的fatalError替换为安全的降级处理
  - activeForm: 替换fatalError为安全降级中
  - createdAt: 2026-02-21 18:00

- [x] **RACE-001 修复MXLog nonisolated(unsafe)静态变量数据竞争** `P0`
  - description: 修复MXLog中nonisolated(unsafe)静态变量的数据竞争
  - activeForm: 修复MXLog数据竞争中
  - createdAt: 2026-02-21 18:00

- [x] **RACE-002 修复NSE targetConfiguration静态变量竞态** `P0`
  - description: 修复NSE中targetConfiguration静态变量的竞态条件
  - activeForm: 修复NSE竞态中
  - createdAt: 2026-02-21 18:00

- [x] **RACE-003 修复ExpiringTaskRunner continuation Actor隔离违规** `P0`
  - description: 修复ExpiringTaskRunner中continuation的Actor隔离违规
  - activeForm: 修复Actor隔离违规中
  - createdAt: 2026-02-21 18:00

- [x] **THREAD-001 修复ClientProxy后台线程Combine Subject.send线程安全** `P1`
  - description: 确保ClientProxy中Combine Subject.send在正确线程上调用
  - activeForm: 修复Subject.send线程安全中
  - createdAt: 2026-02-21 18:00

- [x] **THREAD-002 修复Combine sink缺少.receive(on: .main)** `P1`
  - description: 为缺少主线程调度的Combine sink添加.receive(on: .main)
  - activeForm: 修复Combine线程调度中
  - createdAt: 2026-02-21 18:00

- [x] **THREAD-003 修复HomeScreenViewModel火和忘Task生命周期泄漏** `P1`
  - description: 修复HomeScreenViewModel中fire-and-forget Task的生命周期泄漏
  - activeForm: 修复Task生命周期泄漏中
  - createdAt: 2026-02-21 18:00

- [x] **THREAD-004 修复UserIndicatorController delayedIndicators Set竞态** `P1`
  - description: 修复delayedIndicators Set的并发读写竞态
  - activeForm: 修复delayedIndicators竞态中
  - createdAt: 2026-02-21 18:00

- [x] **LEAK-001 修复TimelineTableViewController通知观察者泄漏** `P1`
  - description: 修复TimelineTableViewController中通知观察者未移除导致的泄漏
  - activeForm: 修复通知观察者泄漏中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-007 修复BlurHashEncode force unwrap崩溃风险** `P1`
  - description: 将BlurHashEncode中的force unwrap替换为安全解包
  - activeForm: 修复BlurHash force unwrap中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-008 修复MapLibreMapView @unknown default fatalError** `P1`
  - description: 将MapLibreMapView中@unknown default的fatalError替换为安全处理
  - activeForm: 修复MapLibre fatalError中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-009 修复AppCoordinator版本解析fatalError** `P1`
  - description: 将AppCoordinator中版本解析的fatalError替换为安全降级
  - activeForm: 修复版本解析fatalError中
  - createdAt: 2026-02-21 18:00

- [x] **SEC-001 将硬编码凭证迁移到安全配置** `P1`
  - description: 将代码中硬编码的凭证迁移到安全的配置方式
  - activeForm: 迁移硬编码凭证中
  - createdAt: 2026-02-21 18:00

- [x] **SEC-002 实现Recovery Key剪贴板自动过期** `P1`
  - description: 实现Recovery Key复制到剪贴板后自动过期清除
  - activeForm: 实现剪贴板自动过期中
  - createdAt: 2026-02-21 18:00

- [x] **SEC-003 为敏感文件添加Complete文件保护属性** `P1`
  - description: 为包含敏感数据的文件设置Complete文件保护级别
  - activeForm: 添加文件保护属性中
  - createdAt: 2026-02-21 18:00

- [x] **SEC-004 为敏感页面添加截屏保护** `P2`
  - description: 为包含敏感信息的页面添加截屏和录屏保护
  - activeForm: 添加截屏保护中
  - createdAt: 2026-02-21 18:00

- [x] **PERF-001 为ForEach添加稳定.id()消除列表抖动** `P2`
  - description: 为ForEach视图添加稳定的.id()以消除列表更新时的抖动
  - activeForm: 添加稳定id中
  - createdAt: 2026-02-21 18:00

- [x] **PERF-002 拆分TimelineViewModel降低复杂度** `P2`
  - description: 拆分过大的TimelineViewModel以降低代码复杂度
  - activeForm: 拆分TimelineViewModel中
  - createdAt: 2026-02-21 18:00

- [x] **PERF-003 合并HomeScreenContent中重复的updateVisibleRange触发** `P2`
  - description: 合并HomeScreenContent中重复触发的updateVisibleRange调用
  - activeForm: 合并updateVisibleRange中
  - createdAt: 2026-02-21 18:00

- [x] **PERF-004 将DispatchQueue.main.asyncAfter迁移为Task.sleep结构化并发** `P2`
  - description: 将DispatchQueue.main.asyncAfter替换为Task.sleep结构化并发方式
  - activeForm: 迁移asyncAfter中
  - createdAt: 2026-02-21 18:00

- [x] **PERF-005 修复OverridableAvatarImage绕过Kingfisher缓存** `P2`
  - description: 修复OverridableAvatarImage未使用Kingfisher缓存的问题
  - activeForm: 修复头像缓存中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-010 修复RoomDirectorySearchProxy数组越界** `P1`
  - description: 修复RoomDirectorySearchProxy中的数组越界崩溃
  - activeForm: 修复RoomDirectorySearch越界中
  - createdAt: 2026-02-21 18:00

- [x] **CRASH-011 修复RoomAvatarImage空用户数组防护** `P2`
  - description: 为RoomAvatarImage添加空用户数组的防护检查
  - activeForm: 修复RoomAvatar空数组中
  - createdAt: 2026-02-21 18:00

---

## 第二迭代 — GIM 品牌化 & 构建优化

- [x] **BRAND-001 替换Localizable.strings中用户可见的Element引用** `P1`
  - description: 替换Localizable.strings中所有用户可见的"Element"文案为"GIM"。涉及：Element Call相关提示（call_invalid_audio_device_bluetooth_devices_disabled）、高级设置中Element Call URL描述（screen_advanced_settings_element_call_*）、Element Pro相关错误提示（screen_change_server_error_element_pro_*）、旧版通话提示（screen_room_timeline_legacy_call）。需在Untranslated.strings中添加覆盖条目。
  - activeForm: 替换用户可见Element文案中
  - createdAt: 2026-02-21 22:00

- [x] **BRAND-002 更新project.yml组织名为GIM** `P1`
  - description: 将project.yml中attributes.ORGANIZATIONNAME从"Element"改为"GIM"，然后运行xcodegen重新生成工程。
  - activeForm: 更新组织名中
  - createdAt: 2026-02-21 22:00

- [x] **BRAND-003 重写README/CONTRIBUTING/SECURITY为GIM品牌** `P2`
  - description: 将README.md、CONTRIBUTING.md、SECURITY.md中的Element X iOS引用替换为GIM。更新项目描述、贡献指引中的Matrix room链接、安全漏洞报告邮箱和URL。保留Matrix协议相关引用不变。
  - activeForm: 重写文档品牌中
  - createdAt: 2026-02-21 22:00

- [x] **BRAND-004 更新CLAUDE.md项目描述为GIM** `P2`
  - description: 将CLAUDE.md中"Element X iOS is a Matrix messaging client"更新为GIM的项目描述，保持技术架构说明不变。
  - activeForm: 更新CLAUDE.md品牌中
  - createdAt: 2026-02-21 22:00

- [x] **BRAND-005 清理测试文件中的element.io引用** `P3`
  - description: 更新测试文件中的element.io域名引用为g.im或通用Matrix域名。涉及文件：AppRouteURLParserTests.swift（app.element.io/develop.element.io）、URLComponentsTests.swift（call.element.io）、AttributedStringBuilderTests.swift（element.io HTML测试数据）、EditRoomAddressScreenViewModelTests.swift（element.io房间别名）。
  - activeForm: 清理测试element.io引用中
  - createdAt: 2026-02-21 22:00

- [x] **BUILD-001 将LoremSwiftum依赖移至测试Target** `P1`
  - description: LoremSwiftum仅用于Mock/Preview数据生成（EventTimelineItem.swift），但当前链接在主ElementX target中会随生产包发布。应将其移至UnitTests/PreviewTests target，或通过条件编译（#if DEBUG）隔离，确保Release包不包含此依赖。修改project.yml后运行xcodegen。
  - activeForm: 迁移LoremSwiftum到测试Target中
  - createdAt: 2026-02-21 22:00

- [x] **BUILD-002 将KZFileWatchers依赖移至测试Target** `P1`
  - description: KZFileWatchers仅用于UITestsSignalling.swift中UI测试与App的文件信号通信，当前链接在主Target。应将其移至UITests target或通过条件编译隔离，确保Release包不包含此开发依赖。修改project.yml后运行xcodegen。
  - activeForm: 迁移KZFileWatchers到测试Target中
  - createdAt: 2026-02-21 22:00

- [x] **CFG-001 配置GIM自有Push Gateway地址** `P1`
  - description: AppSettings.swift第262行pushGatewayBaseURL默认为"https://matrix.org"（公共Matrix.org服务器）。GIM使用自建服务器，需将默认推送网关地址更新为GIM自有服务器地址，或通过环境变量/配置文件注入。需同步确认GIM服务端Push Gateway是否已部署。
  - activeForm: 配置Push Gateway地址中
  - createdAt: 2026-02-21 22:00

- [x] **CFG-002 更新默认accountProviders为GIM服务器** `P1`
  - description: AppSettings.swift第183行accountProviders默认为["matrix.org"]。GIM应默认指向自有服务器（g.im），使用户首次打开即连接GIM服务器而非matrix.org。验收标准：登录页默认显示GIM服务器地址。
  - activeForm: 更新默认accountProviders中
  - createdAt: 2026-02-21 22:00

- [x] **CFG-003 移除或替换Sentry注释中的element.io链接** `P2`
  - description: AppCoordinator.swift中第1138/1200行包含Sentry element.io链接的注释。替换为GIM自有Sentry实例URL或移除过时的issue链接注释。
  - activeForm: 清理Sentry注释链接中
  - createdAt: 2026-02-21 22:00

- [x] **BUILD-003 移除Dynamic空依赖** `P2`
  - description: 依赖审计发现Dynamic包0处使用。从project.yml中移除该SPM依赖，运行xcodegen验证编译通过。
  - activeForm: 移除Dynamic依赖中
  - createdAt: 2026-02-21 22:00

- [x] **BUILD-004 审计并精简Release构建体积** `P2`
  - description: 确认Release配置下未包含开发专用代码：1）验证LoremSwiftum/KZFileWatchers在BUILD-001/002完成后确实不链接；2）检查Mocks/目录是否被Release包含；3）评估当前ipa体积与可优化空间。产出体积审计报告。
  - activeForm: 审计Release构建体积中
  - createdAt: 2026-02-21 22:00
  - blocked by: BUILD-001, BUILD-002

- [x] **L10N-001 建立GIM本地化工作流** `P2`
  - description: Element X使用Localazy管理翻译，GIM fork需建立独立的本地化流程：1）评估是否继续使用Localazy或切换其他方案；2）确保Untranslated.strings中的GIM品牌覆盖正确应用；3）确认中文翻译覆盖率。
  - activeForm: 建立本地化工作流中
  - createdAt: 2026-02-21 22:00

- [x] **SEC-005 审计App Transport Security配置** `P1`
  - description: 检查Info.plist中的NSAppTransportSecurity配置，确保：1）未开放NSAllowsArbitraryLoads；2）仅对必要域名设置例外；3）GIM自有服务器（g.im）通信强制HTTPS。输出ATS合规报告。
  - activeForm: 审计ATS配置中
  - createdAt: 2026-02-21 22:00

- [x] **SEC-006 审计Keychain访问控制与数据分类** `P1`
  - description: 审计KeychainAccess使用情况：1）确认OIDC token存储使用正确的kSecAttrAccessible级别（应为kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly或更严格）；2）确认Keychain service名和access group与GIM bundle ID一致（im.g.message）；3）检查是否有敏感数据误存UserDefaults。
  - activeForm: 审计Keychain访问控制中
  - createdAt: 2026-02-21 22:00

---

## 第三迭代 — MapLibre → Apple MapKit 迁移

- [ ] **MAP-001 替换MapLibreMapView为SwiftUI Map** `P1`
  - description: 将MapLibreMapView.swift（UIViewRepresentable包装MLNMapView）替换为SwiftUI原生Map组件。需迁移：1）交互式地图渲染（pan/zoom）；2）用户位置追踪（hide/show/showAndFollow三种模式）；3）相机控制与区域变更回调；4）定位权限状态监听；5）深色/浅色模式自动适配（MapKit原生支持）。iOS 18.5+部署目标可直接使用MapKit SwiftUI API。
  - activeForm: 替换MapLibreMapView为SwiftUI Map中
  - createdAt: 2026-02-22 00:00

- [ ] **MAP-002 替换LocationAnnotation为MapKit Annotation** `P1`
  - description: 将LocationAnnotation.swift（基于MLNAnnotation/MLNAnnotationView的自定义标注）替换为SwiftUI Map的Annotation组件。保留现有SwiftUI ViewBuilder标注视图，移除UIHostingController包装层。
  - activeForm: 替换LocationAnnotation中
  - createdAt: 2026-02-22 00:00
  - blocked by: MAP-001

- [ ] **MAP-003 替换MapLibreStaticMapView为MKMapSnapshotter** `P1`
  - description: 将MapLibreStaticMapView.swift（通过MapTiler API加载静态瓦片PNG）替换为MKMapSnapshotter本地渲染。需迁移：1）按坐标/缩放级别生成静态地图图片；2）叠加自定义Pin标注；3）3:2宽高比和最大300pt高度约束；4）深色/浅色样式适配。MKMapSnapshotter无需网络API Key，离线也可渲染缓存区域。
  - activeForm: 替换静态地图为MKMapSnapshotter中
  - createdAt: 2026-02-22 00:00

- [ ] **MAP-004 适配StaticLocationScreen使用新Map API** `P1`
  - description: 更新StaticLocationScreen.swift（位置分享/查看页面）适配MAP-001/002的新MapKit实现。确保：1）选择位置模式正常工作（拖动地图选点）；2）查看位置模式正确显示Pin；3）用户位置按钮和权限流程不变；4）错误处理适配（移除MapLibreError，使用MapKit错误）。
  - activeForm: 适配StaticLocationScreen中
  - createdAt: 2026-02-22 00:00
  - blocked by: MAP-001, MAP-002

- [ ] **MAP-005 适配LocationRoomTimelineView使用新静态地图** `P1`
  - description: 更新LocationRoomTimelineView.swift（时间线中的位置消息预览），将MapTiler静态瓦片URL替换为MAP-003的MKMapSnapshotter实现。确保缩略图渲染性能在列表滚动中可接受（考虑缓存策略）。
  - activeForm: 适配时间线位置预览中
  - createdAt: 2026-02-22 00:00
  - blocked by: MAP-003

- [ ] **MAP-006 移除MapTiler配置和URL构建器** `P1`
  - description: 删除不再需要的MapTiler相关文件：1）MapTilerConfiguration.swift；2）MapTilerURLBuilderProtocol.swift；3）MapURLs.swift（MapTilerConfiguration扩展）。清理AppSettings.swift中的mapTilerBaseURL和mapTilerApiKey配置。清理project.yml或target.yml中的MAPTILER_API_KEY环境变量。
  - activeForm: 移除MapTiler配置中
  - createdAt: 2026-02-22 00:00
  - blocked by: MAP-003, MAP-004, MAP-005

- [ ] **MAP-007 简化MapLibreModels为MapKit模型** `P1`
  - description: 重构MapLibreModels.swift：1）保留ShowUserLocationMode枚举（通用）；2）移除MapLibreError替换为适当的MapKit错误处理；3）移除MapTilerStyle枚举（MapKit自动适配主题）；4）移除MapTilerAttributionPlacement枚举；5）文件重命名为MapModels.swift。
  - activeForm: 简化地图模型中
  - createdAt: 2026-02-22 00:00
  - blocked by: MAP-004

- [ ] **MAP-008 从project.yml移除MapLibre依赖** `P1`
  - description: 从project.yml中移除MapLibre SPM依赖（maplibre-gl-native-distribution 6.22.1）。从ElementX target依赖列表中移除MapLibre包引用。运行xcodegen重新生成工程。预计减少二进制体积5-10MB。
  - activeForm: 移除MapLibre依赖中
  - createdAt: 2026-02-22 00:00
  - blocked by: MAP-006, MAP-007
