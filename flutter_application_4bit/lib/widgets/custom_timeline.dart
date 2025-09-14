import 'package:flutter/material.dart';

class CustomTimeline {
  static Widget buildTimeLineBuilder(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;

    // Only show hour labels at the top of each hour
    if (minute != 0) {
      return const SizedBox.shrink();
    }

    String timeLabel;
    if (hour == 0) {
      timeLabel = '12AM';
    } else if (hour < 12) {
      timeLabel = '${hour}AM';
    } else if (hour == 12) {
      timeLabel = '12PM';
    } else {
      timeLabel = '${hour - 12}PM';
    }

    return Container(
      width: 50,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        timeLabel,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}