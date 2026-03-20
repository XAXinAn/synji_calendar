import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';
import '../utils/app_constants.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../models/group.dart';
import 'create_group_page.dart';
import 'join_group_page.dart';
import 'group_detail_page.dart';

class GroupSharingPage extends StatefulWidget {
  const GroupSharingPage({super.key});

  @override
  State<GroupSharingPage> createState() => _GroupSharingPageState();
}

class _GroupSharingPageState extends State<GroupSharingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthService>().user?.token;
      context.read<GroupService>().fetchMyGroups(token);
    });
  }

  // 仿微信排序逻辑：中英文混排，按拼音 A-Z 排序
  int _compareGroups(Group a, Group b) {
    String pinyinA = PinyinHelper.getPinyinE(a.name, separator: "", defPinyin: '#', format: PinyinFormat.WITHOUT_TONE).toLowerCase();
    String pinyinB = PinyinHelper.getPinyinE(b.name, separator: "", defPinyin: '#', format: PinyinFormat.WITHOUT_TONE).toLowerCase();
    return pinyinA.compareTo(pinyinB);
  }

  @override
  Widget build(BuildContext context) {
    final groupService = context.watch<GroupService>();
    final authService = context.watch<AuthService>();
    final userId = authService.user?.id;
    final groups = groupService.myGroups;

    // 分类小组
    final createdGroups = groups.where((g) => g.creatorId == userId).toList();
    createdGroups.sort(_compareGroups);

    final joinedGroups = groups.where((g) => g.creatorId != userId).toList();
    joinedGroups.sort(_compareGroups);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('组内日程共享'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textMain,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showActionSheet(context),
          ),
        ],
      ),
      body: groupService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => groupService.fetchMyGroups(authService.user?.token),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (createdGroups.isNotEmpty) ...[
                        _buildSectionHeader('我创建的小组', Icons.stars_rounded, Colors.orange),
                        ...createdGroups.map((g) => _buildGroupCard(g)),
                        const SizedBox(height: 16),
                      ],
                      if (joinedGroups.isNotEmpty) ...[
                        _buildSectionHeader('我加入的小组', Icons.group_rounded, Colors.blue),
                        ...joinedGroups.map((g) => _buildGroupCard(g)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              group.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.vpn_key_outlined, size: 12, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Text(group.inviteCode, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(width: 12),
            const Icon(Icons.people_outline, size: 12, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Text('${group.memberCount} 成员', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textLightGrey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailPage(group: group),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            '暂无共享小组',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 40),
          _buildActionButton(
            context,
            Icons.add,
            '创建小组',
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage())),
            true,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            Icons.group_add,
            '加入小组',
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinGroupPage())),
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onPressed, bool primary) {
    return SizedBox(
      width: 200,
      height: 48,
      child: primary 
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: const Text('创建小组'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: AppColors.primary),
              title: const Text('加入小组'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinGroupPage()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
