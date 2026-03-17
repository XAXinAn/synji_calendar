import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('会员权益', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '核心权益',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    icon: Icons.auto_awesome,
                    title: 'AI 智能识图建历',
                    desc: '拍照或上传图片，自动提取日程信息并一键加入日历。',
                    color: Colors.blue,
                  ),
                  _buildBenefitItem(
                    icon: Icons.cloud_sync,
                    title: '多端数据同步',
                    desc: '登录账号，实时同步您的日程安排，永不丢失。',
                    color: Colors.green,
                  ),
                  _buildBenefitItem(
                    icon: Icons.all_inclusive,
                    title: '无限日程存储',
                    desc: '没有任何数量限制，记录您生活中的每一个精彩瞬间。',
                    color: Colors.orange,
                  ),
                  _buildBenefitItem(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: '纯净无广告体验',
                    desc: '专注于时间管理，拒绝任何形式的广告打扰。',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 32),
                  _buildStatusCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            '讯极日历 Pro',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '开启高效生活新篇章',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String desc, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
              const SizedBox(width: 8),
              Text(
                '限时免费公告',
                style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '目前软件处于公测阶段，为了感谢您的支持，当前所有功能均对全体用户免费开放，无需订阅即可畅享完整体验。',
            style: TextStyle(color: Colors.amber[900], fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
