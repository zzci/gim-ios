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
### CRASH-001 2026-02-21 18:00 P0 修复LoginScreenViewModel用户名分割数组越界 DONE
### CRASH-002 2026-02-21 18:00 P0 修复MXLog路径组件数组越界 DONE
### CRASH-003 2026-02-21 18:00 P0 修复TypingIndicatorView成员数组越界竞态 DONE
### CRASH-004 2026-02-21 18:00 P0 修复RoomSummaryProvider popFront空数组崩溃 DONE
### CRASH-005 2026-02-21 18:00 P0 修复AuthenticationService accountProviders空数组崩溃 DONE
### CRASH-006 2026-02-21 18:00 P0 将AppCoordinator中7处fatalError替换为安全降级 DONE
### RACE-001 2026-02-21 18:00 P0 修复MXLog nonisolated(unsafe)静态变量数据竞争 DONE
### RACE-002 2026-02-21 18:00 P0 修复NSE targetConfiguration静态变量竞态 DONE
### RACE-003 2026-02-21 18:00 P0 修复ExpiringTaskRunner continuation Actor隔离违规 DONE
### THREAD-001 2026-02-21 18:00 P1 修复ClientProxy后台线程Combine Subject.send线程安全 DONE
### THREAD-002 2026-02-21 18:00 P1 修复Combine sink缺少.receive(on: .main) DONE
### THREAD-003 2026-02-21 18:00 P1 修复HomeScreenViewModel火和忘Task生命周期泄漏 DONE
### THREAD-004 2026-02-21 18:00 P1 修复UserIndicatorController delayedIndicators Set竞态 DONE
### LEAK-001 2026-02-21 18:00 P1 修复TimelineTableViewController通知观察者泄漏 DONE
### CRASH-007 2026-02-21 18:00 P1 修复BlurHashEncode force unwrap崩溃风险 DONE
### CRASH-008 2026-02-21 18:00 P1 修复MapLibreMapView @unknown default fatalError DONE
### CRASH-009 2026-02-21 18:00 P1 修复AppCoordinator版本解析fatalError DONE
### SEC-001 2026-02-21 18:00 P1 将硬编码凭证迁移到安全配置 DONE
### SEC-002 2026-02-21 18:00 P1 实现Recovery Key剪贴板自动过期 DONE
### SEC-003 2026-02-21 18:00 P1 为敏感文件添加Complete文件保护属性 DONE
### SEC-004 2026-02-21 18:00 P2 为敏感页面添加截屏保护 DONE
### PERF-001 2026-02-21 18:00 P2 为ForEach添加稳定.id()消除列表抖动 DONE
### PERF-002 2026-02-21 18:00 P2 拆分TimelineViewModel降低复杂度 DONE
### PERF-003 2026-02-21 18:00 P2 合并HomeScreenContent中重复的updateVisibleRange触发 DONE
### PERF-004 2026-02-21 18:00 P2 将DispatchQueue.main.asyncAfter迁移为Task.sleep结构化并发 DONE
### PERF-005 2026-02-21 18:00 P2 修复OverridableAvatarImage绕过Kingfisher缓存 DONE
### CRASH-010 2026-02-21 18:00 P1 修复RoomDirectorySearchProxy数组越界 DONE
### CRASH-011 2026-02-21 18:00 P2 修复RoomAvatarImage空用户数组防护 DONE

## 待办任务
