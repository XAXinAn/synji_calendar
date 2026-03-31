import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/device_calendar_service.dart';
import '../utils/app_constants.dart';
import '../utils/ui_utils.dart';
import 'add_schedule_page.dart';

class OcrConfirmPage extends StatefulWidget {
  final List<Schedule> initialSchedules;

  const OcrConfirmPage({
    super.key,
    required this.initialSchedules,
  });

  @override
  State<OcrConfirmPage> createState() => _OcrConfirmPageState();
}

class _OcrConfirmPageState extends State<OcrConfirmPage> {
  late List<Schedule> _schedules;
  late List<bool> _selectedItems;
  bool _saveToApp = true;
  bool _saveToSystem = false;
  final DeviceCalendarService _deviceCalendarService = DeviceCalendarService();

  @override
  void initState() {
    super.initState();
    _schedules = List.from(widget.initialSchedules);
    _selectedItems = List.filled(_schedules.length, true);
  }

  Future<void> _handleConfirm() async {
    final selectedSchedules = <Schedule>[];
    for (int i = 0; i < _schedules.length; i++) {
      if (_selectedItems[i]) {
        selectedSchedules.add(_schedules[i]);
      }
    }

    if (selectedSchedules.isEmpty) {
      UIUtils.showToast(context, '请至少选择一个日程');
      return;
    }

    if (!_saveToApp && !_saveToSystem) {
      UIUtils.showToast(context, '请选择保存位置（App 或 系统日历）');
      return;
    }

    final scheduleService = context.read<ScheduleService>();
    scheduleService.setProcessing(true, message: '正在保存日程...');

    try {
      int appSuccessCount = 0;
      int systemSuccessCount = 0;

      if (_saveToApp) {
        for (var s in selectedSchedules) {
          await scheduleService.addSchedule(s);
          appSuccessCount++;
        }
      }

      if (_saveToSystem) {
        systemSuccessCount = await _deviceCalendarService.syncAllToDevice(selectedSchedules);
      }

      scheduleService.setProcessing(false);
      
      if (mounted) {
        String message = '保存完成！';
        if (_saveToApp) message += ' App日程+$appSuccessCount';
        if (_saveToSystem) message += ' 系统日历+$systemSuccessCount';
        
        Navigator.pop(context); 
        UIUtils.showToast(context, message, backgroundColor: AppColors.success);
      }
    } catch (e) {
      scheduleService.setProcessing(false);
      if (mounted) {
        UIUtils.showToast(context, '保存出错: $e', backgroundColor: AppColors.error);
      }
    }
  }

  void _editScheduleDetail(int index) async {
    final editedSchedule = await Navigator.push<Schedule>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSchedulePage(
          schedule: _schedules[index],
          isReviewMode: true,
        ),
      ),
    );

    if (editedSchedule != null) {
      setState(() {
        _schedules[index] = editedSchedule;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('核对识别结果'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_schedules.isNotEmpty)
            TextButton(
              onPressed: () {
                bool allSelected = _selectedItems.every((e) => e);
                setState(() {
                  _selectedItems = List.filled(_schedules.length, !allSelected);
                });
              },
              child: Text(_selectedItems.every((e) => e) ? '全不选' : '全选'),
            ),
        ],
      ),
      body: _schedules.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final s = _schedules[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Slidable(
                          key: Key(s.id + index.toString()),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.2,
                            children: [
                              SlidableAction(
                                onPressed: (_) => setState(() {
                                  _schedules.removeAt(index);
                                  _selectedItems.removeAt(index);
                                }),
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ],
                          ),
                          child: _buildScheduleItem(s, index),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomPanel(),
              ],
            ),
    );
  }

  Widget _buildScheduleItem(Schedule s, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: CheckboxListTile(
        value: _selectedItems[index],
        onChanged: (val) => setState(() => _selectedItems[index] = val ?? false),
        activeColor: AppColors.primary,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Row(
          children: [
            Expanded(
              child: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
              onPressed: () => _editScheduleDetail(index),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 13, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(DateFormat('yyyy-MM-dd HH:mm').format(s.dateTime), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
            if (s.location != null && s.location!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(s.location!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('存入软件日程', style: TextStyle(fontSize: 14)),
                    value: _saveToApp,
                    onChanged: (val) => setState(() => _saveToApp = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('存入系统日历', style: TextStyle(fontSize: 14)),
                    value: _saveToSystem,
                    onChanged: (val) => setState(() => _saveToSystem = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('确认添加所选', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.playlist_remove_rounded, size: 64, color: AppColors.textLightGrey),
          const SizedBox(height: 16),
          const Text('暂无待核对日程', style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
          const SizedBox(height: 24),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('返回')),
        ],
      ),
    );
  }
}
