import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../utils/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    _schedules = List.from(widget.initialSchedules);
  }

  Future<void> _confirmAll() async {
    if (_schedules.isEmpty) {
      Navigator.pop(context);
      return;
    }
    
    final scheduleService = context.read<ScheduleService>();
    
    try {
      for (var s in _schedules) {
        await scheduleService.addSchedule(s);
      }
      
      if (mounted) {
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已成功存入本地库 (${_schedules.length} 条)'),
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF323232),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'), 
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.fixed,
          ),
        );
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

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('核对日程信息'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _schedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_remove_rounded, size: 64, color: AppColors.textLightGrey),
                  const SizedBox(height: 16),
                  const Text('暂无待核对日程', style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回重试'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final s = _schedules[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Slidable(
                          key: Key(s.id + index.toString()),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  _removeSchedule(index);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('已移除: ${s.title}'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.fixed,
                                      backgroundColor: const Color(0xFF323232),
                                    ),
                                  );
                                },
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '删除',
                                borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                s.title, 
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          DateFormat('yyyy-MM-dd HH:mm').format(s.dateTime),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (s.location != null && s.location!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.redAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            s.location!,
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                              onTap: () => _editScheduleDetail(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _schedules.isEmpty ? null : _confirmAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('确认并添加至本机', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
