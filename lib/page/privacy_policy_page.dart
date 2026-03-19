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
            Text(
              '更新日期：2024年1月1日\n生效日期：2024年1月1日',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '导言',
              '讯极日历是由 讯极技术团队 (Synji Tech Team)（以下简称“我们”）提供的移动应用。我们非常重视您的个人信息保护和隐私保护。我们将通过本《隐私政策》帮助您了解我们收集、使用、存储、共享和保护个人信息的情况，以及您所享有的相关权利。',
            ),
            _buildSection(
              '1. 信息收集与使用',
              '为了向您提供核心服务，我们会收集必要的信息：\n'
              '• 注册认证：收集用户名和加密密码，用于账号创建与登录验证。\n'
              '• 日程管理：收集您创建的日程标题、时间、地点等，用于云端同步，确保数据在多端一致。\n'
              '• AI 解析服务：当您使用 OCR 识别时，我们会临时处理图片/文字，提取日程要素。',
            ),
            _buildSection(
              '2. 账号注销流程',
              '我们为您提供了便捷的账号注销渠道。您可以按照以下路径操作：\n'
              '路径：进入“我的” -> “设置” -> “注销账号”。\n'
              '在您注销账号后，我们将停止为您提供全部产品或服务，并依据法律法规要求通过匿名化或删除的方式处理您的个人信息。',
            ),
            _buildSection(
              '3. 个性化推送与关闭',
              '本应用目前不含广告推荐。如未来涉及个性化内容推荐，我们会在“设置”中提供明显的开关。您可以通过“设置 -> 隐私设置 -> 个性化推荐”选择关闭。关闭后，我们将不再基于您的偏好为您展示定制化内容。',
            ),
            _buildSection(
              '4. 儿童个人信息保护',
              '我们非常重视对未成年人个人信息的保护。若您是不满14周岁的儿童，在您使用本产品前，应事先取得您的家长或法定监护人的书面同意。',
            ),
            _buildSection(
              '5. 权限使用说明',
              '• 网络权限：用于云端同步与 AI 解析。\n'
              '• 相机/相册：仅在您主动发起 OCR 识别时申请，用于获取日程图片。',
            ),
            _buildSection(
              '6. 研发方信息',
              '研发主体：讯极技术团队 (Synji Tech Team)\n'
              '联系方式：synji_support@example.com',
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
                    '© 2024 Synji Calendar All Rights Reserved',
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
