import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../utils/ui_utils.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../services/device_calendar_service.dart';

class AddSchedulePage extends StatefulWidget {
  final Schedule? schedule;
  final bool isFromOcr;
  final bool isReviewMode;
  final DateTime? initialDate;
  final String? targetGroupId;

  const AddSchedulePage({
    super.key, 
    this.schedule, 
    this.isFromOcr = false,
    this.isReviewMode = false,
    this.initialDate,
    this.targetGroupId,
  });

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late DateTime _selectedDateTime;
  String? _selectedGroupId;
  final DeviceCalendarService _deviceCalendarService = DeviceCalendarService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule?.title ?? '');
    _descController = TextEditingController(text: widget.schedule?.description ?? '');
    _locationController = TextEditingController(text: widget.schedule?.location ?? '');
    
    _selectedGroupId = widget.targetGroupId ?? widget.schedule?.groupId;
    
    if (widget.schedule != null) {
      _selectedDateTime = widget.schedule!.dateTime;
    } else if (widget.initialDate != null) {
      final now = DateTime.now();
      _selectedDateTime = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        now.hour,
        now.minute,
      );
    } else {
      _selectedDateTime = DateTime.now();
    }
  }

  bool _canEdit() {
    if (widget.schedule == null || widget.isFromOcr || widget.isReviewMode) return true;
    if (widget.schedule!.groupId == null || widget.schedule!.groupId!.isEmpty) return true;
    
    final userId = context.read<AuthService>().user?.id;
    final groups = context.read<GroupService>().myGroups;
    final group = groups.where((g) => g.id == widget.schedule!.groupId).firstOrNull;
    
    if (group == null || userId == null) return false;
    return group.isAdmin(userId);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    if (!_canEdit()) return;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _showSaveOptionsDialog(Schedule schedule) async {
    bool saveToApp = true;
    bool saveToSystem = false;

    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          title: const Text('选择保存位置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionCard(
                title: '存入软件日程',
                subtitle: '多端同步，支持小组共享',
                icon: Icons.cloud_done_rounded,
                selected: saveToApp,
                onTap: () => setState(() => saveToApp = !saveToApp),
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                title: '存入系统日历',
                subtitle: '在手机自带日历中查看',
                icon: Icons.calendar_today_rounded,
                selected: saveToSystem,
                onTap: () => setState(() => saveToSystem = !saveToSystem),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: (!saveToApp && !saveToSystem) ? null : () => Navigator.pop(context, {'app': saveToApp, 'system': saveToSystem}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('确定保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _executeSave(schedule, result['app']!, result['system']!);
    }
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textGrey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? AppColors.primary : AppColors.textMain, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              Icon(Icons.radio_button_unchecked, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _executeSave(Schedule schedule, bool toApp, bool toSystem) async {
    final authService = context.read<AuthService>();
    final scheduleService = context.read<ScheduleService>();
    final user = authService.user;

    scheduleService.setProcessing(true, message: '正在处理...');
    
    try {
      bool appSuccess = true;
      bool systemSuccess = true;

      if (toApp) {
        if (widget.schedule == null || widget.isFromOcr) {
          await scheduleService.addSchedule(schedule, token: user?.token);
        } else {
          await scheduleService.updateSchedule(schedule, token: user?.token);
        }
      }

      if (toSystem) {
        systemSuccess = await _deviceCalendarService.addToDeviceCalendar(schedule);
      }

      scheduleService.setProcessing(false);
      if (!mounted) return;

      if (appSuccess && systemSuccess) {
        Navigator.pop(context);
        String msg = toApp && toSystem ? '已保存至 App 并同步到系统日历' : (toApp ? '日程保存成功' : '已成功添加至系统日历');
        UIUtils.showToast(context, msg);
      } else if (!systemSuccess) {
        UIUtils.showToast(context, 'App 保存成功，但系统日历写入失败（请检查权限）');
      }
    } catch (e) {
      scheduleService.setProcessing(false);
      if (!mounted) return;
      UIUtils.showToast(context, '保存失败: $e');
    }
  }

  Future<void> _saveSchedule() async {
    if (!_canEdit()) return;
    if (_formKey.currentState!.validate()) {
      final authService = context.read<AuthService>();
      final user = authService.user;

      final schedule = Schedule(
        id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dateTime: _selectedDateTime,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        groupId: _selectedGroupId,
        creatorName: widget.schedule?.creatorName ?? user?.nickname ?? user?.username,
      );
      
      if (widget.isReviewMode) {
        Navigator.pop(context, schedule);
      } else {
        await _showSaveOptionsDialog(schedule);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit();
    final isEditing = widget.schedule != null && !widget.isFromOcr && !widget.isReviewMode;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isReviewMode ? '核对详情' : (isEditing ? '日程详情' : '新建日程')),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(widget.isReviewMode ? Icons.arrow_back : Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _saveSchedule,
                child: Text(
                  widget.isReviewMode ? '完成' : '保存',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacings.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard([
                _buildTextField(
                  controller: _titleController,
                  hint: '日程标题',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  enabled: canEdit,
                  validator: (value) => (value == null || value.trim().isEmpty) ? '请输入标题' : null,
                ),
                const Divider(height: 1, color: AppColors.divider),
                _buildTextField(
                  controller: _descController,
                  hint: '添加描述',
                  maxLines: 3,
                  enabled: canEdit,
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                _buildListTile(
                  icon: Icons.access_time_filled_rounded,
                  iconColor: Colors.orange,
                  label: '时间',
                  value: DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                  onTap: () => _selectDateTime(context),
                  enabled: canEdit,
                ),
                const Divider(height: 1, indent: 52, color: AppColors.divider),
                _buildTextField(
                  controller: _locationController,
                  hint: '地点（选填）',
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.redAccent,
                  enabled: canEdit,
                ),
              ]),
              if (widget.schedule?.creatorName != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '由 ${widget.schedule!.creatorName} 创建',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
              ],
              if (isEditing && canEdit) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final token = context.read<AuthService>().user?.token;
                      context.read<ScheduleService>().removeSchedule(widget.schedule!.id, token: token);
                      Navigator.pop(context);
                      UIUtils.showToast(context, '日程已删除');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
                      ),
                    ),
                    child: const Text(
                      '删除日程',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Color? iconColor,
    int maxLines = 1,
    double fontSize = 15,
    FontWeight? fontWeight,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              enabled: enabled,
              validator: validator,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: enabled ? AppColors.textMain : AppColors.textGrey,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textLightGrey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacings.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: enabled ? iconColor : AppColors.textLightGrey, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: enabled ? AppColors.textMain : AppColors.textGrey),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 15, color: enabled ? AppColors.textGrey : AppColors.textLightGrey),
            ),
            if (enabled)
              const Icon(Icons.chevron_right, color: AppColors.textLightGrey, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
