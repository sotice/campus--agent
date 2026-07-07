import 'models.dart';

/// Mock schedule data for demo student "张三" (Zhang San)
/// Student ID: 2024001001, Department: 计算机科学学院
class MockScheduleData {
  static const String demoStudentId = '2024001001';
  static const String demoStudentName = '张三';

  static final List<ScheduleEntry> entries = [
    const ScheduleEntry(
      courseName: '数据结构与算法',
      teacher: '王教授',
      classroom: 'A301',
      building: '1号教学楼',
      startPeriod: 1,
      endPeriod: 2,
      dayOfWeek: 'Monday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '大学英语(三)',
      teacher: '李老师',
      classroom: 'B205',
      building: '2号教学楼',
      startPeriod: 3,
      endPeriod: 4,
      dayOfWeek: 'Monday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '计算机网络',
      teacher: '张教授',
      classroom: 'C102',
      building: '3号教学楼',
      startPeriod: 1,
      endPeriod: 2,
      dayOfWeek: 'Tuesday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '操作系统原理',
      teacher: '刘教授',
      classroom: 'A405',
      building: '1号教学楼',
      startPeriod: 3,
      endPeriod: 4,
      dayOfWeek: 'Tuesday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '数据库系统',
      teacher: '陈老师',
      classroom: 'B301',
      building: '2号教学楼',
      startPeriod: 5,
      endPeriod: 6,
      dayOfWeek: 'Tuesday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '人工智能导论',
      teacher: '赵教授',
      classroom: 'A201',
      building: '1号教学楼',
      startPeriod: 1,
      endPeriod: 2,
      dayOfWeek: 'Wednesday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '软件工程',
      teacher: '孙老师',
      classroom: 'C203',
      building: '3号教学楼',
      startPeriod: 3,
      endPeriod: 4,
      dayOfWeek: 'Wednesday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '数据结构与算法(实验)',
      teacher: '王教授',
      classroom: '机房201',
      building: '实验楼',
      startPeriod: 1,
      endPeriod: 4,
      dayOfWeek: 'Thursday',
      weeks: '1-8',
    ),
    const ScheduleEntry(
      courseName: '思想政治教育',
      teacher: '周老师',
      classroom: 'D101',
      building: '4号教学楼',
      startPeriod: 5,
      endPeriod: 6,
      dayOfWeek: 'Thursday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '体育(篮球)',
      teacher: '吴老师',
      classroom: '体育馆',
      building: '体育中心',
      startPeriod: 1,
      endPeriod: 2,
      dayOfWeek: 'Friday',
      weeks: '1-16',
    ),
    const ScheduleEntry(
      courseName: '计算机网络(实验)',
      teacher: '张教授',
      classroom: '机房301',
      building: '实验楼',
      startPeriod: 5,
      endPeriod: 8,
      dayOfWeek: 'Friday',
      weeks: '5-12',
    ),
  ];

  /// Get schedule for a specific day
  static List<ScheduleEntry> getScheduleForDay(String day) {
    return entries.where((e) => e.dayOfWeek == day).toList()
      ..sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
  }

  /// Get today's schedule (simulated as Monday for demo)
  static List<ScheduleEntry> getTodaySchedule() {
    return getScheduleForDay('Monday');
  }

  /// Get full weekly schedule
  static Map<String, List<ScheduleEntry>> getWeeklySchedule() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return {for (var d in days) d: getScheduleForDay(d)};
  }

  /// Search schedule by keyword
  static List<ScheduleEntry> search(String query) {
    final q = query.toLowerCase();
    return entries.where((e) {
      return e.courseName.toLowerCase().contains(q) ||
          e.teacher.toLowerCase().contains(q) ||
          e.building.toLowerCase().contains(q) ||
          e.classroom.toLowerCase().contains(q);
    }).toList();
  }
}
