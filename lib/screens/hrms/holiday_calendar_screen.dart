import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutanvij_electricals/screens/hrms/apply_leave_screen.dart';
import 'package:nutanvij_electricals/widgets/custom_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive.dart';
import 'leave_request_list_screen.dart';

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Example holiday data
  final List<Map<String, dynamic>> holidays = [
    {'date': DateTime(2025, 5, 1), 'name': 'Labour Day'},
    {'date': DateTime(2025, 5, 8), 'name': 'Buddha Purnima'},
    {'date': DateTime(2025, 5, 25), 'name': 'Some Festival'},
    {'date': DateTime(2025, 6, 15), 'name': 'Summer Break'},
    // Add more holidays here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.responsiveValue(
              context: context, mobile: 12, tablet: 32),
          vertical: Responsive.responsiveValue(
              context: context, mobile: 8, tablet: 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(context),
            Expanded(
              child: Container(),
            ),
            CustomButton(text: "View My Leave", onPressed: () {
              NavigationUtils.push(
                  context,
                  const LeaveRequestListScreen(isAllUsers: false));
            }),
            SizedBox(
              height: Responsive.responsiveValue(
                  context: context, mobile: 18, tablet: 46),
            ),
            CustomButton(text: "Apply For a Leave", onPressed: () {
              NavigationUtils.push(
                  context, const ApplyLeaveScreen());
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom,)
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMonthHolidays() {
    return holidays
        .where((h) =>
            h['date'].year == _selectedMonth.year &&
            h['date'].month == _selectedMonth.month)
        .toList();
  }

  Widget _buildCalendar(BuildContext context) {
    final firstDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final cellSize =
        Responsive.responsiveValue(context: context, mobile: 32, tablet: 48);
    final cellRadius =
        Responsive.responsiveValue(context: context, mobile: 8, tablet: 14);
    final monthHolidays = _getMonthHolidays();
    final holidayDays = monthHolidays.map((h) => h['date'].day).toSet();
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.responsiveValue(
              context: context, mobile: 16, tablet: 32)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.responsiveValue(
                context: context, mobile: 16, tablet: 24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(monthName,
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        iconSize: Responsive.getIconSize(context),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                                _selectedMonth.year, _selectedMonth.month - 1);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        iconSize: Responsive.getIconSize(context),
                        onPressed: () {
                          setState(() {
                            _selectedMonth = DateTime(
                                _selectedMonth.year, _selectedMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                  height: Responsive.responsiveValue(
                      context: context, mobile: 8, tablet: 16)),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sun'),
                  Text('Mon'),
                  Text('Tue'),
                  Text('Wed'),
                  Text('Thu'),
                  Text('Fri'),
                  Text('Sat'),
                ],
              ),
              SizedBox(
                  height: Responsive.responsiveValue(
                      context: context, mobile: 4, tablet: 8)),
              Column(
                children: List.generate(
                  ((daysInMonth + firstWeekday) / 7).ceil(),
                  (week) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (day) {
                        int dayNum = week * 7 + day - firstWeekday + 1;
                        if (week == 0 && day < firstWeekday ||
                            dayNum < 1 ||
                            dayNum > daysInMonth) {
                          return SizedBox(width: cellSize);
                        }
                        Color? bg;
                        if (holidayDays.contains(dayNum)) {
                          bg = Colors.red.shade200;
                        }
                        return GestureDetector(
                          onTap: () {
                            final holiday = monthHolidays.firstWhere(
                              (h) => h['date'].day == dayNum,
                              orElse: () => {},
                            );
                            if (holiday.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Holiday'),
                                  content: Text(holiday['name']),
                                  actions: [
                                    TextButton(
                                        onPressed: () => NavigationUtils.pop(context),
                                        child: const Text('OK'))
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(cellRadius),
                            ),
                            child: Center(
                              child: Text(
                                dayNum.toString(),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: holidayDays.contains(dayNum)
                                      ? Colors.red.shade900
                                      : Colors.black,
                                  fontWeight: holidayDays.contains(dayNum)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
