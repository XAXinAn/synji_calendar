import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/schedule_service.dart';
import '../models/schedule.dart';
import '../utils/app_constants.dart';
import 'add_schedule_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('zh_CN', null);
    _selectedDay = _focusedDay;
    // 初始化时同步选中日期给 Service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleService>().setSelectedDate(_selectedDay!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final dailySchedules = scheduleService.getSchedulesForDay(_selectedDay ?? _focusedDay);

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _buildCalendarCard(scheduleService),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '今日日程',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dailySchedules.length} 个任务',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Expanded(
            child: dailySchedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: dailySchedules.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleItem(dailySchedules[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(ScheduleService service) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
      child: TableCalendar(
        locale: 'zh_CN',
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        rowHeight: 48,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          context.read<ScheduleService>().setSelectedDate(selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 12),
          formatButtonPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        eventLoader: (day) {
          return service.getSchedulesForDay(day);
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
                      DateFormat('HH:mm').format(schedule.dateTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.circle, size: 8, color: AppColors.primary),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (schedule.location != null && schedule.location!.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 64, color: AppColors.textLightGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              '暂无日程安排',
              style: TextStyle(color: AppColors.textGrey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
