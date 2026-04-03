# Code Review Report

**项目**: Synji Calendar (讯极日历)
**版本**: 1.0.0+1
**审查日期**: 2026-04-03
**审查范围**: Flutter/Dart 移动应用全量源代码

---

## P0 - Critical (严重安全问题)

### P0-1: 硬编码的API密钥泄露
**文件**: `config.json`
**行号**: 2
**问题描述**:
```json
{
  "DASHSCOPE_API_KEY": "sk-10903522ee714643a059fb4ccc80f2d4"
}
```
在配置文件中硬编码了阿里云DashScope的API密钥。该密钥可以访问AI服务，导致严重的安全风险。

**严重程度**: 攻击者可以利用此密钥进行API滥用或产生不必要的费用。所有使用此密钥的服务都可能受到影响。

**修复建议**:
1. 将API密钥移至环境变量或安全的密钥管理服务
2. 从版本控制中删除此文件并添加到.gitignore
3. 轮换已泄露的API密钥

---

### P0-2: 使用已弃用的WillPopScope API
**文件**: `lib/page/main_screen.dart`
**行号**: 99-100
**问题描述**:
```dart
builder: (context) => WillPopScope(
  onWillPop: () async => false,
```
Flutter已弃用`WillPopScope`，应使用`PopScope`。

**严重程度**: 在新版本Flutter中可能导致编译警告或运行时问题，影响应用稳定性。

**修复建议**: 替换为`PopScope` API。

---

## P1 - High (高优先级问题)

### P1-1: 静默catch块吞掉错误
**文件**: `lib/services/group_service.dart`
**行号**: 47, 75, 85, 95
**问题描述**:
```dart
} catch (e) {}
```
多处使用空的catch块，会静默吞掉所有异常，使用户无法得知操作失败的原因。

**严重程度**: 用户执行操作失败后看到成功提示，但实际上操作未完成，导致数据不一致和用户体验问题。

**修复建议**: 至少记录错误日志，或向用户显示操作失败的通知。

---

### P1-2: OCR结果打印到控制台
**文件**: `lib/utils/ocr_service.dart`
**行号**: 17-21
**问题描述**:
```dart
print('--- OCR 识别开始 ---');
for (TextBlock block in recognizedText.blocks) {
  print('Detected block: ${block.text}');
}
print('--- OCR 识别结束 ---');
```
OCR识别的敏感内容被打印到控制台日志。

**严重程度**: 在生产环境中可能泄露用户隐私信息（如截图中的日程内容）。

**修复建议**: 使用专业的日志库（如logger）并设置适当的日志级别，或完全移除此调试代码。

---

### P1-3: 用户输入缺乏验证
**文件**: 多个文件
**涉及位置**:
- `lib/page/register_page.dart` - 用户名、密码无服务端校验
- `lib/page/join_group_page.dart` - 邀请码无格式验证
- `lib/page/create_group_page.dart` - 小组名称无长度/内容限制

**问题描述**: 用户输入未进行长度限制、特殊字符过滤等基本验证。

**严重程度**: 可能导致后端API接受恶意构造的数据，引发安全问题。

**修复建议**: 添加前端输入验证：
- 用户名：6-20字符，字母数字下划线
- 密码：至少6字符
- 邀请码：固定长度验证
- 小组名称：长度限制

---

### P1-4: Dio日志拦截器记录敏感信息
**文件**: `lib/services/schedule_service.dart`
**行号**: 47-51
**问题描述**:
```dart
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  logPrint: (obj) => debugPrint('🌐 [Network] $obj'),
));
```
启用后会将完整的请求和响应体记录到日志，包括可能包含敏感信息的API调用。

**严重程度**: 在生产环境或调试时可能泄露token、密码等敏感数据。

**修复建议**: 在生产构建中禁用详细日志，或使用条件编译排除敏感日志。

---

### P1-5: SyncStatus错误处理不完善
**文件**: `lib/services/schedule_service.dart`
**行号**: 263-267
**问题描述**:
```dart
void _handleSyncError(dynamic e, bool silent) {
  _syncStatus = SyncStatus.error;
  if (!silent) setProcessing(false);
  notifyListeners();
}
```
错误信息被忽略，用户不知道同步失败的原因。

**严重程度**: 同步失败时用户界面显示不清晰，无法采取补救措施。

**修复建议**: 保存错误信息并在UI中向用户展示。

---

## P2 - Medium (中等优先级问题)

### P2-1: 日程ID基于时间戳可能冲突
**文件**: `lib/page/add_schedule_page.dart`
**行号**: 251
**问题描述**:
```dart
id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
```
使用毫秒级时间戳作为ID，在快速连续创建日程时可能产生冲突。

**严重程度**: 多设备同步时可能覆盖或丢失日程。

**修复建议**: 使用UUID或组合方案（时间戳+随机数+设备ID）。

---

### P2-2: 测试文件与实际应用不匹配
**文件**: `test/widget_test.dart`
**行号**: 14-29
**问题描述**:
```dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsNothing);
  await tester.tap(find.byIcon(Icons.add));
  ...
```
自动生成的测试文件引用了不存在的计数器功能，与实际应用功能不符。

**严重程度**: 运行测试会失败，影响CI/CD流程。

**修复建议**: 删除或重写测试以匹配实际应用功能。

---

### P2-3: 异常处理信息暴露内部细节
**文件**: 多个文件
**涉及位置**:
- `lib/page/login_page.dart` - `'$e'` 直接显示异常信息
- `lib/page/register_page.dart` - `'注册失败：$e'`
- `lib/page/add_schedule_page.dart` - `'$e'`

**问题描述**: 错误信息包含完整的异常堆栈或内部实现细节。

**严重程度**: 可能向攻击者泄露系统内部信息。

**修复建议**: 使用用户友好的错误消息，不暴露技术细节。

---

### P2-4: 小组删除权限校验依赖前端
**文件**: `lib/page/group_detail_page.dart`
**行号**: 140
**问题描述**:
```dart
floatingActionButton: isAdmin && !_isSelectionMode ? FloatingActionButton(...)
```
小组日程的删除按钮显示逻辑依赖前端判断，后端API规范(BACKEND_API_SPEC.md)要求后端必须校验权限。

**严重程度**: 如果后端未实现权限校验，可能导致非管理员删除他人日程。

**修复建议**: 前端仅作为UX优化，主要权限校验应在后端实现。

---

### P2-5: 没有请求超时和重试机制
**文件**: `lib/services/auth_service.dart`
**行号**: 27-32
**问题描述**:
```dart
_dio = Dio(BaseOptions(
  baseUrl: AppConfig.baseUrl,
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 3),
```
较短的超时时间和缺乏重试机制可能导致网络不稳定时同步失败。

**严重程度**: 用户在网络不佳时可能丢失数据。

**修复建议**: 实现指数退避重试机制和更长的超时时间。

---

## P3 - Low (低优先级问题)

### P3-1: 代码注释提到"核心修复"但无Issue引用
**文件**: 多个文件
**涉及位置**:
- `lib/page/home_page.dart` - "【核心修复】"
- `lib/page/profile_page.dart` - "【核心修复】"

**问题描述**: 代码注释表明之前存在bug修复，但没有Issue或PR引用。

**严重程度**: 较低，仅影响代码可维护性。

---

### P3-2: 错误消息未国际化
**文件**: 多个文件
**问题描述**: 所有错误消息硬编码为中文，不支持多语言。

**严重程度**: 不利于应用国际化扩展。

---

### P3-3: 隐私弹窗使用exit(0)退出应用
**文件**: `lib/page/main_screen.dart`
**行号**: 147
**问题描述**:
```dart
TextButton(onPressed: () => exit(0), child: const Text('不同意并退出', style: TextStyle(color: AppColors.textGrey))),
```
直接调用`exit(0)`会立即终止应用，用户可能丢失未保存的数据。

**严重程度**: 用户选择不同意隐私政策时可能丢失数据。

**修复建议**: 先提示用户数据未保存，然后优雅退出。

---

### P3-4: 数据库版本迁移缺少回滚机制
**文件**: `lib/services/database_helper.dart`
**行号**: 25-34
**问题描述**: 数据库迁移（ALTER TABLE）不支持降级，如果新版本应用在某些设备上失败，可能导致数据库损坏。

**严重程度**: 应用更新失败时用户可能无法回滚到旧版本。

---

### P3-5: 缺少网络状态变化的适当处理
**文件**: `lib/page/main_screen.dart`
**行号**: 57-63
**问题描述**: 连接恢复时自动同步，但没有检查是否有正在进行中的同步操作。

**严重程度**: 可能导致并发同步问题。

---

## 总结

### 高危问题统计
| 级别 | 数量 | 说明 |
|------|------|------|
| P0 | 2 | 严重安全问题需要立即修复 |
| P1 | 5 | 高优先级问题影响安全或功能 |
| P2 | 5 | 中优先级问题影响用户体验 |
| P3 | 5 | 低优先级问题影响可维护性 |

### 修复优先级建议
1. **立即修复**: P0问题 - API密钥泄露和WillPopScope弃用
2. **尽快修复**: P1问题 - 静默错误处理、敏感信息泄露、输入验证
3. **计划修复**: P2问题 - ID生成、测试匹配、超时重试
4. **后续优化**: P3问题 - 国际化、代码注释、优雅退出

### 特别关注
1. **config.json中的API密钥必须立即处理** - 建议轮换密钥并使用环境变量
2. 所有网络请求的日志记录需要审查，确保不记录敏感信息
3. 建议实现统一的错误处理框架，避免静默失败
