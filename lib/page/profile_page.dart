import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          
          // 1. 个人信息卡片
          _buildHeaderCard(context),
          
          const SizedBox(height: 16),
          
          // 2. 会员卡片 (原服务卡片)
          _buildSectionCard([
            _buildMenuItem(Icons.card_membership, '会员', iconColor: Colors.amber[700]!),
          ]),
          
          const SizedBox(height: 16),
          
          // 3. 设置卡片 (原第四个卡片)
          _buildSectionCard([
            _buildMenuItem(Icons.settings, '设置', iconColor: Colors.blue),
          ]),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 头部个人信息卡片
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue[50],
            ),
            child: Icon(Icons.person, size: 40, color: Colors.blue[300]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用户昵称',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '微信号：wx_12345678',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.qr_code, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
        ],
      ),
    );
  }

  // 通用的组卡片容器
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // 菜单项
  Widget _buildMenuItem(IconData icon, String title, {required Color iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[300]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: () {},
    );
  }
}
