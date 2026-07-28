import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/expense_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Stream<List<Expense>> _expenseStream;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime.utc(now.year, now.month, now.day);
    _focusedDay = now;
    _expenseStream = context.read<ExpenseProvider>().allExpenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Expense Calendar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expenseStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textDim,
              ),
            );
          }

          final allExpenses = snapshot.data ?? [];
          final expensesByDay = _groupExpensesByDay(allExpenses);
          
          final selectedExpenses = allExpenses.where((e) => isSameDay(e.date, _selectedDay)).toList();

          return Column(
            children: [
              _buildCalendar(expensesByDay),
              const SizedBox(height: 24),
              if (_selectedDay != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    DateFormat('MMMM dd, yyyy').format(_selectedDay!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildExpenseList(selectedExpenses),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<Expense>> expensesByDay) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: TableCalendar(
        rowHeight: 64,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay =
                DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          markerSize: 0
          // Custom builders will override these
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: AppColors.textSecondary),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
        eventLoader: (day) {
          final normalizedDay = DateTime.utc(day.year, day.month, day.day);
          return expensesByDay[normalizedDay] ?? [];
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildCalendarDay(day,
                isSelected: false, isToday: false, expenses: expensesByDay);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildCalendarDay(day,
                isSelected: true, isToday: false, expenses: expensesByDay);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarDay(day,
                isSelected: false, isToday: true, expenses: expensesByDay);
          },
          outsideBuilder: (context, day, focusedDay) {
            return const SizedBox.shrink(); // Hide outside days for a cleaner look
          },
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day,
      {required bool isSelected,
      required bool isToday,
      required Map<DateTime, List<Expense>> expenses}) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    final dayExpenses = expenses[utcDay] ?? [];
    final total = dayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Container(
      width: 200,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.textPrimary
            : total > 0
                ? AppColors.textPrimary.withValues(alpha: 0.3)
                : isToday
                    ? AppColors.iconBg
                    : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? null
            : Border.all(
                color: total > 0
                    ? AppColors.textPrimary.withOpacity(0.2)
                    : AppColors.border,
                width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textPrimary,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '₹${total.toInt()}',
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses for this day',
          style: TextStyle(color: AppColors.textDim, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseTile(
          expense: expense,
          onDelete: () => context.read<ExpenseProvider>().delete(expense.id),
        );
      },
    );
  }

  Map<DateTime, List<Expense>> _groupExpensesByDay(List<Expense> expenses) {
    final Map<DateTime, List<Expense>> data = {};
    for (var expense in expenses) {
      // Create UTC midnight keys to match calendar selection
      final date = DateTime.utc(
          expense.date.year, expense.date.month, expense.date.day);
      if (data[date] == null) {
        data[date] = [];
      }
      data[date]!.add(expense);
    }
    return data;
  }
}
