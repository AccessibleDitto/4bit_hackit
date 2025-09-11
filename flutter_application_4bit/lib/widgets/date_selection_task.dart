import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateTimePickerButton extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String selectedDateType;
  final Function(DateTime?, TimeOfDay?, String) onDateTimeSelected;

  const DateTimePickerButton({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedDateType,
    required this.onDateTimeSelected,
  }) : super(key: key);

  @override
  _DateTimePickerButtonState createState() => _DateTimePickerButtonState();
}

class _DateTimePickerButtonState extends State<DateTimePickerButton> {
  DateTime? tempSelectedDate;
  TimeOfDay? tempSelectedTime;
  String tempSelectedDateType = 'Today';
  bool showTimePicker = false;

  final Map<String, DateOption> dateOptions = {
    'Today': DateOption(
      label: 'Today',
      icon: Icons.today,
      color: const Color(0xFF10B981), // Emerald from your theme
    ),
    'Tomorrow': DateOption(
      label: 'Tomorrow',
      icon: Icons.wb_sunny,
      color: const Color(0xFFF97316), // Orange from your theme
    ),
    'Later this week': DateOption(
      label: 'Later this week',
      icon: Icons.date_range,
      color: const Color(0xFF3B82F6), // Blue from your theme
    ),
    'This weekend': DateOption(
      label: 'This weekend',
      icon: Icons.weekend,
      color: const Color(0xFF9333EA), // Primary purple from your theme
    ),
    'Next week': DateOption(
      label: 'Next week',
      icon: Icons.next_week,
      color: const Color(0xFF7C3AED), // Secondary purple from your theme
    ),
    'No Date': DateOption(
      label: 'No Date',
      icon: Icons.clear,
      color: const Color(0xFF71717A), // Grey from your theme
    ),
  };

  String _getButtonText() {
    if (widget.selectedDate == null) {
      return 'No Date';
    }

    String dateText = _formatDate(widget.selectedDate!);
    if (widget.selectedTime != null) {
      String timeText = widget.selectedTime!.format(context);
      return '$dateText at $timeText';
    }
    return dateText;
  }

  Color _getButtonColor() {
    return dateOptions[widget.selectedDateType]?.color ??
        const Color(0xFF71717A);
  }

  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today && widget.selectedDateType == 'Today') {
      return 'Today';
    } else if (selectedDay == tomorrow &&
        widget.selectedDateType == 'Tomorrow') {
      return 'Tomorrow';
    } else if (widget.selectedDateType == 'Later this week') {
      return 'Later this week';
    } else if (widget.selectedDateType == 'This weekend') {
      return 'This weekend';
    } else if (widget.selectedDateType == 'Next week') {
      return 'Next week';
    } else {
      // Custom date format: "5 Sep"
      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  DateTime _getDateForOption(String option) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    switch (option) {
      case 'Today':
        return today;
      case 'Tomorrow':
        return today.add(const Duration(days: 1));
      case 'Later this week':
        // Find next weekday (Monday-Friday)
        int daysUntilFriday = 5 - now.weekday; // Monday = 1, Friday = 5
        if (daysUntilFriday <= 0) daysUntilFriday = 7 + daysUntilFriday;
        return today.add(Duration(days: daysUntilFriday));
      case 'This weekend':
        // Find next Saturday
        int daysUntilSaturday = 6 - now.weekday; // Saturday = 6
        if (daysUntilSaturday <= 0) daysUntilSaturday = 7 + daysUntilSaturday;
        return today.add(Duration(days: daysUntilSaturday));
      case 'Next week':
        // Find next Monday
        int daysUntilNextMonday = 8 - now.weekday; // Next Monday
        return today.add(Duration(days: daysUntilNextMonday));
      default:
        return today;
    }
  }

  void _showTimePicker() async {
    final TimeOfDay? selectedTime = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => TimePickerScreen(
          initialTime: tempSelectedTime ?? TimeOfDay.now(),
          onTimeSelected: (time) {
            setState(() {
              tempSelectedTime = time;
            });
          },
        ),
      ),
    );

    if (selectedTime != null) {
      setState(() {
        tempSelectedTime = selectedTime;
      });
    }
  }

  void _showDateTimePicker() {
    tempSelectedDate = widget.selectedDate ?? DateTime.now();
    tempSelectedTime = widget.selectedTime;
    tempSelectedDateType = widget.selectedDateType;
    showTimePicker = widget.selectedTime != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF18181B), // Dark background from your theme
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF71717A), // Grey from your theme
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF71717A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Due Date',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onDateTimeSelected(
                          tempSelectedDate,
                          tempSelectedTime,
                          tempSelectedDateType,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9333EA), // Primary purple
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick date options
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children:
                              [
                                    'Today',
                                    'Tomorrow',
                                    'Later this week',
                                    'This weekend',
                                    'Next week',
                                    'No Date',
                                  ]
                                  .map(
                                    (option) => _QuickDateOption(
                                      option: dateOptions[option]!,
                                      isSelected:
                                          tempSelectedDateType == option,
                                      onTap: () {
                                        setModalState(() {
                                          tempSelectedDateType = option;

                                          if (option == 'No Date') {
                                            tempSelectedDate = null;
                                            tempSelectedTime = null;
                                            showTimePicker = false;
                                          } else {
                                            // Update the date according to the option
                                            tempSelectedDate =
                                                _getDateForOption(option);

                                            // Important: manually reset the CalendarDatePicker's initialDate
                                            // by simply assigning tempSelectedDate
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),

                      Container(
                        height: 1,
                        color: const Color(0xFF71717A).withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),

                      if (tempSelectedDate != null) ...[
                        // Calendar section with fixed height
                        Container(
                          height: 400,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors
                                    .deepPurple, // Selected day / header background
                                onPrimary: Colors
                                    .white, // Text on selected day / header
                                // surface:
                                //     Colors.grey[200]!, // Background of calendar
                                onSurface: const Color(0xFF71717A), // Default text color
                              ),
                            ),
                            child: CalendarDatePicker(
                              key: ValueKey(
                                tempSelectedDate,
                              ), // <-- Add this line
                              initialDate: tempSelectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                              onDateChanged: (date) {
                                setModalState(() {
                                  tempSelectedDate = date;
                                  tempSelectedDateType = 'Custom';
                                });
                              },
                            ),
                          ),
                        ),

                        // Time picker section
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showTimePicker();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(
                                    0xFF71717A,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: tempSelectedTime != null
                                    ? const Color(0xFF9333EA).withOpacity(0.1)
                                    : const Color(0xFF27272A).withOpacity(0.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: tempSelectedTime != null
                                        ? const Color(0xFF9333EA)
                                        : const Color(0xFF71717A),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    tempSelectedTime != null
                                        ? 'Time: ${tempSelectedTime!.format(context)}'
                                        : 'Add time',
                                    style: GoogleFonts.inter(
                                      color: tempSelectedTime != null
                                          ? const Color(0xFF9333EA)
                                          : const Color(0xFF71717A),
                                      fontSize: 16,
                                      fontWeight: tempSelectedTime != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (tempSelectedTime != null)
                                    GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempSelectedTime = null;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFF71717A),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Show message if no date selected
                        Container(
                          height: 400,
                          color: const Color(0xFF18181B),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: const Color(0xFF71717A),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No due date set',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: const Color(0xFFA1A1AA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = _getButtonColor();

    return OutlinedButton.icon(
      onPressed: _showDateTimePicker,
      icon: Icon(Icons.calendar_today, color: buttonColor),
      label: Text(
        _getButtonText(),
        style: GoogleFonts.inter(
          color: buttonColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: buttonColor.withValues(alpha: 0.5)),
        backgroundColor: const Color(0xFF27272A).withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class DateOption {
  final String label;
  final IconData icon;
  final Color color;

  DateOption({required this.label, required this.icon, required this.color});
}

class _QuickDateOption extends StatelessWidget {
  final DateOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withValues(alpha: 0.15)
                : const Color(0xFF27272A).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? option.color.withValues(alpha: 0.8)
                  : const Color(0xFF71717A).withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: option.color, size: 20),
              const SizedBox(width: 12),
              Text(
                option.label,
                style: GoogleFonts.inter(
                  color: isSelected ? option.color : const Color(0xFFA1A1AA),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full-screen Time Picker
class TimePickerScreen extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const TimePickerScreen({
    Key? key,
    required this.initialTime,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  _TimePickerScreenState createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: Text(
          'Select Time',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onTimeSelected(selectedTime);
              Navigator.pop(context, selectedTime);
            },
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                color: const Color(0xFF9333EA), // Primary purple
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Selected Time',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFA1A1AA),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedTime.format(context),
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9333EA), // Primary purple
                  ),
                ),
                const SizedBox(height: 32),
                TimePickerSpinner(
                  time: selectedTime,
                  onTimeChange: (time) {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Time Picker Spinner Widget
class TimePickerSpinner extends StatefulWidget {
  final TimeOfDay time;
  final Function(TimeOfDay) onTimeChange;

  const TimePickerSpinner({
    Key? key,
    required this.time,
    required this.onTimeChange,
  }) : super(key: key);

  @override
  _TimePickerSpinnerState createState() => _TimePickerSpinnerState();
}

class _TimePickerSpinnerState extends State<TimePickerSpinner> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.time.hour;
    selectedMinute = widget.time.minute;
    _hourController = FixedExtentScrollController(initialItem: selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onTimeChanged() {
    widget.onTimeChange(TimeOfDay(hour: selectedHour, minute: selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9333EA).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hour picker
          SizedBox(
            width: 80,
            child: ListWheelScrollView.useDelegate(
              controller: _hourController,
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                if (index >= 0 && index < 24) {
                  setState(() {
                    selectedHour = index;
                  });
                  _onTimeChanged();
                }
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index > 23) return null;
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: index == selectedHour
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: index == selectedHour
                            ? const Color(0xFF9333EA) // Primary purple
                            : const Color(0xFF71717A), // Grey
                      ),
                    ),
                  );
                },
                childCount: 24,
              ),
            ),
          ),

          Text(
            ' : ',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Minute picker
          SizedBox(
            width: 80,
            child: ListWheelScrollView.useDelegate(
              controller: _minuteController,
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                if (index >= 0 && index < 60) {
                  setState(() {
                    selectedMinute = index;
                  });
                  _onTimeChanged();
                }
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index > 59) return null;
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: index == selectedMinute
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: index == selectedMinute
                            ? const Color(0xFF9333EA) // Primary purple
                            : const Color(0xFF71717A), // Grey
                      ),
                    ),
                  );
                },
                childCount: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
