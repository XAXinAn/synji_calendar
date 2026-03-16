import 'package:flutter/material.dart';
import 'package:synji_calendar/utils/app_constants.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 MediaQuery 获取安全区域，适配各种刘海屏
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacings.pagePadding),
        children: [
          SizedBox(height: statusBarHeight + 20),
          
          // 1. 个人信息卡片
          const _HeaderCard(
            name: '用户昵称',
            phone: '138****8888',
          ),
          
          const SizedBox(height: 16),
          
          // 2. 会员卡片
          _buildSectionCard([
            _MenuItem(
              icon: Icons.card_membership,
              title: '会员',
              iconColor: Colors.amber[700]!,
              onTap: () {},
            ),
          ]),
          
          const SizedBox(height: 16),
          
          // 3. 设置卡片
          _buildSectionCard([
            _MenuItem(
              icon: Icons.settings,
              title: '设置',
              iconColor: AppColors.primary,
              onTap: () {},
            ),
          ]),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 通用的组卡片容器
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// 头部信息组件 - 抽取为私有组件提高可读性
class _HeaderCard extends StatelessWidget {
  final String name;
  final String phone;

  const _HeaderCard({required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '手机号：$phone',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.qr_code, size: 20, color: AppColors.textLightGrey),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLightGrey),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: const Icon(Icons.person, size: 40, color: AppColors.primary),
    );
  }
}

// 菜单项组件 - 抽取为私有组件
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title, 
        style: const TextStyle(fontSize: 15, color: AppColors.textMain),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLightGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      // 确保点击波纹也是圆角的
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacings.cardRadius)),
      onTap: onTap,
    );
  }
}
