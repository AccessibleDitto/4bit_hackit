import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../utils/date_utils.dart';

class EventDialogs {
  static Widget buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  static Widget buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  static void showEventDetails(
    BuildContext context, 
    CalendarEventData event,
    Map<String?, Color> projectColors,
    Function(BuildContext, CalendarEventData) onEdit,
    Function(BuildContext, CalendarEventData) onDelete,
  ) {
    final extendedEvent = event is ExtendedCalendarEventData ? event : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 380,
              maxWidth: 360,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.description?.isNotEmpty == true) ...[
                    buildSectionTitle("Description"),
                    Text(event.description!),
                    const SizedBox(height: 12),
                  ],
                  buildSectionTitle("Date"),
                  Text("${CalendarDateUtils.getMonthName(event.date.month)} ${event.date.day}, ${event.date.year}"),
                  const SizedBox(height: 12),
                  buildSectionTitle("Time"),
                  Text("${CalendarDateUtils.formatTime(event.startTime!)} - ${CalendarDateUtils.formatTime(event.endTime!)}"),
                  if (extendedEvent != null) ...[
                    const SizedBox(height: 12),
                    buildSectionTitle("Priority"),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: PriorityHelper.priorityColors[extendedEvent.priority],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(PriorityHelper.priorityLabels[extendedEvent.priority]!),
                      ],
                    ),
                    if (extendedEvent.project != null) ...[
                      const SizedBox(height: 12),
                      buildSectionTitle("Project"),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: projectColors[extendedEvent.project] ?? Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              extendedEvent.project!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (extendedEvent.recurring != RecurringType.none) ...[
                      const SizedBox(height: 12),
                      buildSectionTitle("Recurring"),
                      Text(RecurringHelper.recurringLabels[extendedEvent.recurring]!),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildActionButton(
                  icon: Icons.edit,
                  text: "Edit",
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit(context, event);
                  },
                ),
                buildActionButton(
                  icon: Icons.delete,
                  text: "Delete",
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete(context, event);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showEventOptions(
    BuildContext context, 
    CalendarEventData event,
    Function(BuildContext, CalendarEventData) onEdit,
    Function(BuildContext, CalendarEventData) onDelete,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Event"),
                onTap: () {
                  Navigator.pop(context);
                  onEdit(context, event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Event", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(context, event);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showDayEvents(
    BuildContext context, 
    List<CalendarEventData<Object?>> events, 
    DateTime date,
    Function(BuildContext, CalendarEventData) onEventDetails,
    Function(BuildContext, CalendarEventData) onEventOptions,
    Function(BuildContext, {DateTime? selectedDate}) onAddEvent,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${CalendarDateUtils.getMonthName(date.month)} ${date.day}, ${date.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (events.isEmpty)
                const Text("No events for this day")
              else
                ...events.map((event) => ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description ?? ''),
                      leading: CircleAvatar(
                        backgroundColor: event.color ?? Colors.blue,
                        radius: 8,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onEventDetails(context, event);
                      },
                      onLongPress: () {
                        Navigator.pop(context);
                        onEventOptions(context, event);
                      },
                    )),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onAddEvent(context, selectedDate: date);
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context, 
    CalendarEventData event,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event deleted'))
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}