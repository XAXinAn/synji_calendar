import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synji_calendar/utils/app_constants.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'membership_page.dart';
import 'cloud_management_page.dart';
import 'edit_profile_page.dart';
import 'privacy_policy_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.user;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacings.pagePadding),
            children: [
              SizedBox(height: statusBarHeight + 20),
              
              // 1. 个人信息卡片
              if (authService.isAuthenticated)
                _HeaderCard(
                  name: user?.nickname ?? '已登录用户',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  },
                )
              else
                _LoginPromptCard(),
              
              const SizedBox(height: 16),
              
              // 2. 会员权益卡片
              _buildSectionCard([
                _MenuItem(
                  icon: Icons.auto_awesome,
                  title: '会员权益',
                  subtitle: '全功能开放 · 畅享无限体验',
                  iconColor: Colors.amber[700]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MembershipPage()),
                    );
                  },
                ),
              ]),
              
              const SizedBox(height: 16),

              // 3. 云端管理卡片 (仅登录后显示)
              if (authService.isAuthenticated) ...[
                _buildSectionCard([
                  _MenuItem(
                    icon: Icons.cloud_queue_outlined,
                    title: '管理云端数据',
                    subtitle: '查看并按需删除云端备份记录',
                    iconColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CloudManagementPage()),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 16),
              ],
              
              // 4. 设置与协议
              _buildSectionCard([
                _MenuItem(
                  icon: Icons.security_outlined,
                  title: '隐私政策',
                  iconColor: Colors.blueGrey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),
                if (authService.isAuthenticated)
                  _MenuItem(
                    icon: Icons.person_off_outlined,
                    title: '注销账号',
                    iconColor: Colors.orange,
                    onTap: () {
                      _showDeleteAccountConfirm(context);
                    },
                  ),
              ]),

              const SizedBox(height: 16),

              // 5. 账号操作
              if (authService.isAuthenticated)
                _buildSectionCard([
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    title: '退出登录',
                    iconColor: Colors.redAccent,
                    onTap: () {
                      _showLogoutConfirm(context);
                    },
                  ),
                ])
              else
                _buildSectionCard([
                  _MenuItem(
                    icon: Icons.login_rounded,
                    title: '立即登录',
                    iconColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                ]),
              
              const SizedBox(height: 32),
            ],
          ),
          if (authService.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

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

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pop(context);
            },
            child: const Text('确定', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注销账号', style: TextStyle(color: Colors.red)),
        content: const Text('注销账号将永久删除您的所有数据且无法恢复。确定要注销吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await context.read<AuthService>().deleteAccount();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('账号已注销，所有数据已清除')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('注销失败: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('确定注销', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _HeaderCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('编辑资料', style: TextStyle(color: AppColors.textGrey.withOpacity(0.8), fontSize: 13)),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textLightGrey),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.account_circle_outlined, size: 40, color: AppColors.primary.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('点击登录', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  SizedBox(height: 8),
                  Text('登录后可同步数据并享受更多功能', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLightGrey),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, this.subtitle, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textMain, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLightGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacings.cardRadius)),
      onTap: onTap,
    );
  }
}
