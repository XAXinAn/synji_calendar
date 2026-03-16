import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../utils/app_constants.dart';
import 'add_schedule_page.dart';

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
    final allSchedules = scheduleService.schedules;
    
    final filteredSchedules = allSchedules.where((schedule) {
      final query = _searchQuery.toLowerCase();
      return schedule.title.toLowerCase().contains(query) ||
             (schedule.description?.toLowerCase().contains(query) ?? false) ||
             (schedule.location?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, // 修改为统一背景色
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white, // 搜索框内白底
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: '搜索标题、描述或地点',
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
          ? _buildEmptyState('输入关键词开始搜索')
          : filteredSchedules.isEmpty
              ? _buildEmptyState('未找到相关日程')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, index) {
                    return _buildScheduleItem(filteredSchedules[index]);
                  },
                ),
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddSchedulePage(schedule: schedule),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                  if (schedule.location != null && schedule.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            schedule.location!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: AppColors.textLightGrey.withOpacity(0.5)),
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
