import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';

class CloudManagementPage extends StatefulWidget {
  const CloudManagementPage({super.key});

  @override
  State<CloudManagementPage> createState() => _CloudManagementPageState();
}

class _CloudManagementPageState extends State<CloudManagementPage> {
  List<Schedule>? _cloudSchedules;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCloudData();
  }

  Future<void> _loadCloudData() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthService>().user?.token;
    final data = await context.read<ScheduleService>().fetchCloudSchedules(token);
    if (mounted) {
      setState(() {
        _cloudSchedules = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    final token = context.read<AuthService>().user?.token;
    final success = await context.read<ScheduleService>().deleteSingleCloudSchedule(token, id);
    if (success && mounted) {
      setState(() {
        _cloudSchedules?.removeWhere((item) => item.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已从云端移除'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('云端数据管理'),
        actions: [
          if (_cloudSchedules != null && _cloudSchedules!.isNotEmpty)
            IconButton(
              onPressed: () => _showClearAllConfirm(),
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: '全部清空',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : _cloudSchedules == null || _cloudSchedules!.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadCloudData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _cloudSchedules!.length,
        itemBuilder: (context, index) {
          final item = _cloudSchedules![index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Slidable(
              key: Key(item.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) => _showDeleteConfirm(item.id),
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline_rounded,
                    label: '移除',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('yyyy年MM月dd日 HH:mm').format(item.dateTime),
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLightGrey),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1, color: AppColors.divider),
                            const SizedBox(height: 12),
                            if (item.location != null && item.location!.isNotEmpty) ...[
                              _buildDetailRow(Icons.location_on_outlined, item.location!),
                              const SizedBox(height: 8),
                            ],
                            if (item.description != null && item.description!.isNotEmpty) ...[
                              _buildDetailRow(Icons.description_outlined, item.description!),
                            ],
                            if ((item.location == null || item.location!.isEmpty) && 
                                (item.description == null || item.description!.isEmpty))
                              const Text('暂无更多详情', style: TextStyle(fontSize: 13, color: AppColors.textLightGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text(
            '云端暂无备份',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击首页同步按钮即可备份到云端',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadCloudData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('刷新列表'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    _showAppDialog(
      title: '确认移除？',
      content: '此操作将从云端服务器永久移除该条记录，手机本地日程不受影响。',
      confirmText: '移除记录',
      isDanger: true,
      onConfirm: () => _deleteItem(id),
    );
  }

  void _showClearAllConfirm() {
    _showAppDialog(
      title: '全部清空',
      content: '确定要一键清除所有云端备份数据吗？此操作无法撤销。',
      confirmText: '确定清除',
      isDanger: true,
      onConfirm: () async {
        final token = context.read<AuthService>().user?.token;
        final success = await context.read<ScheduleService>().clearCloudSchedules(token);
        if (success) _loadCloudData();
      },
    );
  }

  void _showAppDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
