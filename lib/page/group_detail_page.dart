import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_constants.dart';
import '../models/group.dart';
import '../models/schedule.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../services/schedule_service.dart';
import 'add_schedule_page.dart';
import 'member_management_page.dart';

class GroupDetailPage extends StatefulWidget {
  final Group group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<Schedule> _groupSchedules = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final token = context.read<AuthService>().user?.token;
    final schedules = await context.read<GroupService>().fetchGroupSchedules(widget.group.id, token);
    
    schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (mounted) {
      setState(() {
        _groupSchedules = schedules;
        _isLoading = false;
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _batchAddToPersonal() async {
    if (_selectedIds.isEmpty) return;

    final scheduleService = context.read<ScheduleService>();
    final authService = context.read<AuthService>();
    int count = 0;

    try {
      for (var id in _selectedIds) {
        final original = _groupSchedules.firstWhere((s) => s.id == id);
        // 创建一个不带 groupId 的副本（存为个人）
        final personalCopy = Schedule(
          id: '${DateTime.now().millisecondsSinceEpoch}_${count++}',
          title: original.title,
          description: original.description,
          dateTime: original.dateTime,
          location: original.location,
          groupId: null, // 标记为个人
          creatorName: original.creatorName,
        );
        await scheduleService.addSchedule(personalCopy, token: authService.user?.token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已成功导入 ${_selectedIds.length} 条日程到个人列表')),
        );
        _toggleSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 退出小组
  Future<void> _handleQuitGroup() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出小组'),
        content: Text('确定要退出“${widget.group.name}”吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final token = context.read<AuthService>().user?.token;
      final success = await context.read<GroupService>().quitGroup(widget.group.id, token);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已退出小组')));
        Navigator.pop(context); // 返回上一页
      }
    }
  }

  // 解散小组 (删除)
  Future<void> _handleDeleteGroup() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解散小组', style: TextStyle(color: AppColors.error)),
        content: Text('确定要彻底解散“${widget.group.name}”吗？此操作不可撤销，组内所有日程将被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('彻底解散'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final token = context.read<AuthService>().user?.token;
      final success = await context.read<GroupService>().deleteGroup(widget.group.id, token);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('小组已解散')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().user;
    final isCreator = user?.id == widget.group.creatorId;
    final isAdmin = widget.group.isAdmin(user?.id ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isSelectionMode ? '已选中 ${_selectedIds.length} 项' : widget.group.name),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close), onPressed: _toggleSelectionMode)
          : null,
        actions: [
          if (!_isSelectionMode && _groupSchedules.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist_rtl_rounded),
              onPressed: _toggleSelectionMode,
              tooltip: '批量导入',
            ),
          if (_isSelectionMode)
            TextButton(
              onPressed: _selectedIds.isEmpty ? null : _batchAddToPersonal,
              child: const Text('导入个人', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          if (!_isSelectionMode)
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) {
                if (value == 'manage') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MemberManagementPage(group: widget.group)));
                } else if (value == 'quit') {
                  _handleQuitGroup();
                } else if (value == 'delete') {
                  _handleDeleteGroup();
                }
              },
              icon: const Icon(Icons.more_vert, color: AppColors.textMain),
              itemBuilder: (context) => [
                if (isCreator)
                  const PopupMenuItem(value: 'manage', child: Row(children: [Icon(Icons.manage_accounts, size: 20), SizedBox(width: 12), Text('成员管理')])),
                if (!isCreator)
                  const PopupMenuItem(value: 'quit', child: Row(children: [Icon(Icons.exit_to_app, size: 20, color: AppColors.error), SizedBox(width: 12), Text('退出小组', style: TextStyle(color: AppColors.error))])),
                if (isCreator)
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, size: 20, color: AppColors.error), SizedBox(width: 12), Text('解散小组', style: TextStyle(color: AppColors.error))])),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _groupSchedules.isEmpty
                  ? _buildEmptyState()
                  : _buildScheduleList(),
            ),
      floatingActionButton: isAdmin && !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSchedulePage(
                      initialDate: DateTime.now(),
                      targetGroupId: widget.group.id,
                    ),
                  ),
                );
                _loadData();
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Center(
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textLightGrey),
              SizedBox(height: 16),
              Text('暂无小组日程', style: TextStyle(color: AppColors.textGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _groupSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _groupSchedules[index];
        final isSelected = _selectedIds.contains(schedule.id);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.divider.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onLongPress: _isSelectionMode ? null : _toggleSelectionMode,
            onTap: () {
              if (_isSelectionMode) {
                _toggleItemSelection(schedule.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSchedulePage(
                      schedule: schedule,
                      targetGroupId: widget.group.id,
                    ),
                  ),
                ).then((_) => _loadData());
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_isSelectionMode) ...[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? AppColors.primary : AppColors.textLightGrey,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedule.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(DateFormat('yyyy-MM-dd HH:mm').format(schedule.dateTime), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        if (schedule.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Text(schedule.location!, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
