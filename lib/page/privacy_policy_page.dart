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
              '更新日期：2026年3月19日\n生效日期：2026年3月19日',
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
              '• 日程数据：您在应用内创建的标题、描述、时间、地点及分类信息，我们将上传至服务器进行加密存储，以确保您在不同设备间的数据一致性。\n'
              '• 辅助信息：包括设备基本信息（如型号、操作系统版本）、日志信息（如操作日志、服务访问时间），用于多端同步识别及基本的故障分析。',
            ),
            _buildSection(
              '2. AI 智能解析服务',
              '当您使用 AI 解析功能（如拍照转日程、图片转日程）时：\n'
              '相关的文字或图片内容会发送至我们的后端服务器进行结构化解析。我们仅提取日程相关的结构化信息（如时间、内容），不会保存您的原始图片副本用于除解析之外的其他目的。',
            ),
            _buildSection(
              '3. 账号注销流程',
              '我们为您提供了便捷的账号注销渠道。您可以按照以下路径操作：\n'
              '路径：进入“我的” -> “注销账号”。\n'
              '在您确认注销账号后，我们将停止为您提供全部产品或服务，并依据法律法规要求，永久删除您的所有云端备份数据。',
            ),
            _buildSection(
              '4. 个性化推送与关闭',
              '本应用目前不含广告推荐系统。如未来涉及个性化内容推荐，我们将在“设置”中提供明显的开关。您可以通过“我的 -> 隐私设置 -> 个性化推荐”选择关闭。关闭后，我们将不再基于您的偏好展示定制化内容。',
            ),
            _buildSection(
              '5. 儿童个人信息保护',
              '我们非常重视对未成年人个人信息的保护。若您是不满 14 周岁的儿童，在您使用本产品前，应事先取得您的家长或法定监护人的书面同意。',
            ),
            _buildSection(
              '6. 权限使用说明',
              '• 网络权限：用于实现云端同步、账号登录及 AI 解析服务。\n'
              '• 相机/相册权限：仅在您主动发起 OCR 识别时申请，用于获取包含日程信息的图片。\n'
              '• 存储权限：用于本地数据库存储及导出功能。',
            ),
            _buildSection(
              '7. 第三方 SDK 目录',
              '为了保障软件稳定运行及实现特定功能（如崩溃日志收集），我们可能会接入第三方服务。',
            ),
            _buildSection(
              '8. 研发方信息',
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
