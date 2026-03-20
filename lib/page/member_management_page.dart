import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class MemberManagementPage extends StatefulWidget {
  final Group group;

  const MemberManagementPage({super.key, required this.group});

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  List<GroupMember> _members = [];
  bool _isLoading = true;
  late Group _currentGroup;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final token = context.read<AuthService>().user?.token;
    final members = await context.read<GroupService>().fetchGroupMembers(_currentGroup.id, token);
    
    // 同时也刷新一下小组信息，确保 adminIds 是最新的
    final groupService = context.read<GroupService>();
    await groupService.fetchMyGroups(token);
    final updatedGroup = groupService.myGroups.firstWhere((g) => g.id == _currentGroup.id, orElse: () => _currentGroup);

    if (mounted) {
      setState(() {
        _members = members;
        _currentGroup = updatedGroup;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAdmin(GroupMember member) async {
    final isAdmin = _currentGroup.adminIds.contains(member.id);
    
    // 检查管理员数量限制 (最多2个，不包括创建者)
    if (!isAdmin && _currentGroup.adminIds.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('每个小组最多只能设置 2 名管理员')),
      );
      return;
    }

    final token = context.read<AuthService>().user?.token;
    final success = await context.read<GroupService>().toggleAdmin(_currentGroup.id, member.id, token);
    
    if (success) {
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAdmin ? '已取消管理员权限' : '已设为管理员')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('成员管理'),
        backgroundColor: AppColors.background,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final isCreator = member.id == _currentGroup.creatorId;
                final isAdmin = _currentGroup.adminIds.contains(member.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCreator ? Colors.orange.withOpacity(0.2) : (isAdmin ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                      child: Text(
                        member.nickname[0],
                        style: TextStyle(
                          color: isCreator ? Colors.orange : (isAdmin ? AppColors.primary : Colors.grey),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(member.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isCreator ? '创建者' : (isAdmin ? '管理员' : '成员')),
                    trailing: isCreator 
                      ? const Icon(Icons.stars, color: Colors.orange)
                      : Switch(
                          value: isAdmin,
                          activeColor: AppColors.primary,
                          onChanged: (value) => _toggleAdmin(member),
                        ),
                  ),
                );
              },
            ),
    );
  }
}
