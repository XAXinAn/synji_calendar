import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
    
    // 【修正点】：确保调用的是 ScheduleService 中的方法，而不是 GroupService
    final schedules = await context.read<ScheduleService>().fetchGroupSchedulesDirect(widget.group.id, token);
    
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

  void _handleDeleteSchedule(Schedule schedule) async {
    final scheduleService = context.read<ScheduleService>();
    final authService = context.read<AuthService>();
    try {
      await scheduleService.removeSchedule(schedule.id, token: authService.user?.token);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('小组日程已删除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectionMode() => setState(() { _isSelectionMode = !_isSelectionMode; _selectedIds.clear(); });
  void _toggleItemSelection(String id) => setState(() { if (_selectedIds.contains(id)) _selectedIds.remove(id); else _selectedIds.add(id); });

  Future<void> _batchAddToPersonal() async {
    if (_selectedIds.isEmpty) return;
    final scheduleService = context.read<ScheduleService>();
    final authService = context.read<AuthService>();
    try {
      for (var id in _selectedIds) {
        final original = _groupSchedules.firstWhere((s) => s.id == id);
        final personalCopy = Schedule(
          id: 'p_${DateTime.now().millisecondsSinceEpoch}_$id',
          title: original.title,
          description: original.description,
          dateTime: original.dateTime,
          location: original.location,
          groupId: null,
          creatorName: original.creatorName,
        );
        await scheduleService.addSchedule(personalCopy, token: authService.user?.token);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已成功导入个人列表'))); _toggleSelectionMode(); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red)); }
  }

  Future<void> _handleQuitGroup() async {
    final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('退出小组'), content: Text('确定要退出“${widget.group.name}”吗？'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('确定'))]));
    if (confirm == true && mounted) {
      final success = await context.read<GroupService>().quitGroup(widget.group.id, context.read<AuthService>().user?.token);
      if (success && mounted) Navigator.pop(context);
    }
  }

  Future<void> _handleDeleteGroup() async {
    final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('解散小组', style: TextStyle(color: AppColors.error)), content: Text('确定要彻底解散“${widget.group.name}”吗？此操作不可撤销，组内所有日程将被删除。'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('彻底解散'))]));
    if (confirm == true && mounted) {
      final success = await context.read<GroupService>().deleteGroup(widget.group.id, context.read<AuthService>().user?.token);
      if (success && mounted) Navigator.pop(context);
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
        actions: [
          if (!_isSelectionMode && _groupSchedules.isNotEmpty) IconButton(icon: const Icon(Icons.checklist_rtl_rounded), onPressed: _toggleSelectionMode),
          if (_isSelectionMode) TextButton(onPressed: _selectedIds.isEmpty ? null : _batchAddToPersonal, child: const Text('导入个人', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
          if (!_isSelectionMode) PopupMenuButton<String>(
            onSelected: (value) { if (value == 'manage') Navigator.push(context, MaterialPageRoute(builder: (context) => MemberManagementPage(group: widget.group))); else if (value == 'quit') _handleQuitGroup(); else if (value == 'delete') _handleDeleteGroup(); },
            itemBuilder: (context) => [
              if (isAdmin) const PopupMenuItem(value: 'manage', child: Row(children: [Icon(Icons.manage_accounts), SizedBox(width: 12), Text('成员管理')])),
              if (!isCreator) const PopupMenuItem(value: 'quit', child: Row(children: [Icon(Icons.exit_to_app, color: AppColors.error), SizedBox(width: 12), Text('退出小组')])),
              if (isCreator) const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, color: AppColors.error), SizedBox(width: 12), Text('解散小组')])),
            ],
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: _loadData, child: _groupSchedules.isEmpty ? _buildEmptyState() : _buildScheduleList(isAdmin)),
      floatingActionButton: isAdmin && !_isSelectionMode ? FloatingActionButton(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddSchedulePage(initialDate: DateTime.now(), targetGroupId: widget.group.id))); _loadData(); }, backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)) : null,
    );
  }

  Widget _buildEmptyState() => ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.3), const Center(child: Column(children: [Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textLightGrey), SizedBox(height: 16), Text('暂无小组日程', style: TextStyle(color: AppColors.textGrey))]))]);

  Widget _buildScheduleList(bool canDelete) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groupSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _groupSchedules[index];
        final isSelected = _selectedIds.contains(schedule.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Slidable(
            key: Key(schedule.id),
            enabled: canDelete && !_isSelectionMode,
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) => _handleDeleteSchedule(schedule),
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: '删除',
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider.withOpacity(0.5), width: isSelected ? 2 : 1),
              ),
              child: InkWell(
                onLongPress: _isSelectionMode ? null : _toggleSelectionMode,
                onTap: () {
                  if (_isSelectionMode) _toggleItemSelection(schedule.id);
                  else Navigator.push(context, MaterialPageRoute(builder: (context) => AddSchedulePage(schedule: schedule, targetGroupId: widget.group.id))).then((_) => _loadData());
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_isSelectionMode) ...[Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? AppColors.primary : AppColors.textLightGrey), const SizedBox(width: 12)],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(schedule.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(children: [const Icon(Icons.access_time_rounded, size: 16, color: Colors.orange), const SizedBox(width: 6), Text(DateFormat('yyyy-MM-dd HH:mm').format(schedule.dateTime), style: const TextStyle(fontSize: 13))]),
                            if (schedule.location != null && schedule.location!.isNotEmpty) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent), const SizedBox(width: 6), Text(schedule.location!, style: const TextStyle(fontSize: 13, color: AppColors.textGrey))])],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
