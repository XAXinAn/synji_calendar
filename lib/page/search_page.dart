import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../models/group.dart';
import '../services/schedule_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import 'add_schedule_page.dart';
import 'group_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final groupService = context.watch<GroupService>();
    final authService = context.watch<AuthService>();
    
    final query = _searchQuery.toLowerCase();
    final bool isAuthenticated = authService.isAuthenticated;

    // 搜索日程
    final filteredSchedules = _searchQuery.isEmpty ? <Schedule>[] : scheduleService.schedules.where((schedule) {
      return schedule.title.toLowerCase().contains(query) ||
             (schedule.description?.toLowerCase().contains(query) ?? false) ||
             (schedule.location?.toLowerCase().contains(query) ?? false);
    }).toList();

    // 搜索小组（仅在登录时执行）
    final filteredGroups = (_searchQuery.isEmpty || !isAuthenticated) ? <Group>[] : groupService.myGroups.where((group) {
      return group.name.toLowerCase().contains(query) ||
             group.inviteCode.toLowerCase().contains(query);
    }).toList();

    final bool hasResults = filteredSchedules.isNotEmpty || filteredGroups.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '搜索日程、小组或邀请码',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textGrey),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textGrey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textGrey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildEmptyState('输入关键词开始搜索', Icons.search_rounded)
          : !hasResults
              ? _buildEmptyState('未找到相关内容', Icons.sentiment_dissatisfied_rounded)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (filteredGroups.isNotEmpty) ...[
                      _buildSectionHeader('相关小组', Icons.group_rounded, Colors.blue),
                      ...filteredGroups.map((g) => _buildGroupItem(g)),
                      const SizedBox(height: 16),
                    ],
                    if (filteredSchedules.isNotEmpty) ...[
                      _buildSectionHeader('相关日程', Icons.event_note_rounded, Colors.orange),
                      ...filteredSchedules.map((s) => _buildScheduleItem(s)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem(Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(group.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
        ),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('邀请码: ${group.inviteCode}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupDetailPage(group: group)),
          );
        },
      ),
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        key: Key(schedule.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) {
                context.read<ScheduleService>().removeSchedule(schedule.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日程已删除')),
                );
              },
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddSchedulePage(schedule: schedule),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      DateFormat('MM-dd').format(schedule.dateTime),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(schedule.dateTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (schedule.description != null && schedule.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          schedule.description!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLightGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
