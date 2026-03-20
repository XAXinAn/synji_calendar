import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class AddSchedulePage extends StatefulWidget {
  final Schedule? schedule;
  final bool isFromOcr;
  final bool isReviewMode;
  final DateTime? initialDate;
  final String? targetGroupId; // 新增：明确指定目标小组ID，为null则为个人

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule?.title ?? '');
    _descController = TextEditingController(text: widget.schedule?.description ?? '');
    _locationController = TextEditingController(text: widget.schedule?.location ?? '');
    
    // 优先级：传入的 targetGroupId > schedule自带的 groupId > null(个人)
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

  Future<void> _saveSchedule() async {
    if (!_canEdit()) return;
    if (_formKey.currentState!.validate()) {
      final authService = context.read<AuthService>();
      final user = authService.user;
      final scheduleService = context.read<ScheduleService>();

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
        try {
          if (widget.schedule == null || widget.isFromOcr) {
            await scheduleService.addSchedule(schedule, token: user?.token);
          } else {
            await scheduleService.updateSchedule(schedule, token: user?.token);
          }
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((widget.schedule == null || widget.isFromOcr) ? '日程保存成功' : '日程更新成功')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('日程已删除')),
                      );
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
              if (isEditing && !canEdit) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    '仅限小组管理员或创建者修改',
                    style: TextStyle(color: AppColors.error, fontSize: 14),
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
