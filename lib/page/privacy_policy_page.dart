import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('隐私政策'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacings.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '讯极日历隐私政策',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '更新日期：2026年3月22日\n生效日期：2026年3月22日',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '导言',
              '讯极日历是由 讯极技术团队 (Synji Tech Team)（以下简称“我们”）提供的移动应用。我们非常重视您的个人信息保护和隐私保护。我们将通过本《隐私政策》帮助您了解我们收集、使用、存储、共享和保护个人信息的情况，以及您所享有的相关权利。',
            ),
            _buildSection(
              '1. 我们收集的信息',
              '为了向您提供核心服务，我们会收集必要的信息：\n'
              '• 账号信息：当您注册账号时，我们会收集您的用户名和加密后的密码，用于账号创建、登录验证及云端同步。\n'
              '• 日程数据：个人日程将上传至服务器加密存储以实现多端同步；若您加入或创建小组，您在该小组内发布的日程信息将对小组内其他成员可见。\n'
              '• 社交关联：当您创建或加入小组时，我们会记录您的用户 ID 与小组的关联关系，用于实现群组协作功能。\n'
              '• 辅助信息：包括设备基本信息（如型号、操作系统版本）、日志信息，用于同步识别及故障分析。',
            ),
            _buildSection(
              '2. AI 智能解析服务',
              '当您使用 AI 解析功能（如拍照转日程、文本解析）时：\n'
              '相关的文字或图片内容会发送至我们的后端服务器进行结构化解析。我们仅提取日程相关的结构化信息（如时间、内容），解析完成后，我们不会保留您的原始图片副本。',
            ),
            _buildSection(
              '3. 账号注销流程',
              '您可以通过“我的” -> “注销账号”进行账号注销。在您确认注销后，我们将立即停止服务，并永久删除您的账号信息及所有云端备份数据。若您是小组创建者，注销账号将导致小组解散；若您是普通成员，注销将移除您的成员身份。',
            ),
            _buildSection(
              '4. 权限使用说明',
              '• 网络权限：用于实现云端同步、账号登录及 AI 解析服务。\n'
              '• 网络状态权限：用于监测联网状态，实现断网后的自动恢复同步。\n'
              '• 相机/相册权限：仅在您主动发起 OCR 识别时申请，用于获取包含日程信息的图片。\n'
              '• 存储权限：用于本地 SQLite 数据库存储。',
            ),
            _buildSection(
              '5. 第三方 SDK 目录',
              '为了保障软件稳定运行，我们接入了必要的第三方 SDK（如网络请求库、本地数据库库）。我们会尽到审慎义务，确保其符合隐私保护要求。',
            ),
            _buildSection(
              '6. 研发方信息',
              '研发主体：讯极技术团队 (Synji Tech Team)\n'
              '联系邮箱：synji_support@example.com',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Column(
                children: [
                  Text(
                    '研发方：讯极技术团队 (Synji Tech Team)',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '© 2026 Synji Calendar All Rights Reserved',
                    style: TextStyle(color: AppColors.textLightGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
