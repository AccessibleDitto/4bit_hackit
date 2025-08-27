import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../models/calendar_models.dart';
import '../utils/date_utils.dart';
import 'event_dialogs.dart';
// import 'package:flutter_application_4bit/calendar_page.dart';

class EventFormDialog {
  static void showEventDialog(
    BuildContext context, {
    required bool isEdit,
    CalendarEventData? event,
    DateTime? selectedDate,
    required List<String> projects,
    required Map<String, Color> projectColors,
    required Function(String) onAddProject,
    required Function(ExtendedCalendarEventData, {RecurringType? overrideRecurring}) onSaveEvent,
    required Function(CalendarEventData) onDeleteEvent,
    required Color Function({String? project, required Priority priority}) resolveEventColor,
    required Function(String) onDeleteSeries,
  }) {
    final isExtended = event is ExtendedCalendarEventData;
    final extendedEvent = isExtended ? event as ExtendedCalendarEventData : null;

    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    DateTime eventDate = event?.date ?? selectedDate ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay.fromDateTime(event?.startTime ?? DateTime.now());
    int durationMinutes = event != null ? event.endTime!.difference(event.startTime!).inMinutes : 60;

    Priority selectedPriority = extendedEvent?.priority ?? Priority.medium;
    String? selectedProject = extendedEvent?.project;
    RecurringType selectedRecurring = extendedEvent?.recurring ?? RecurringType.none;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Event' : 'Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: eventDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() => eventDate = date);
                        }
                      },
                      child: Text("${CalendarDateUtils.getMonthName(eventDate.month)} ${eventDate.day}, ${eventDate.year}"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Start: '),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (time != null) {
                          setState(() => startTime = time);
                        }
                      },
                      child: Text(startTime.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Duration: '),
                    Expanded(
                      child: Slider(
                        value: durationMinutes.toDouble(),
                        min: 15,
                        max: 480, // 8 hours
                        divisions: 31, // 15 min intervals
                        label: '${(durationMinutes / 60).toStringAsFixed(1)} hours',
                        onChanged: (value) {
                          setState(() => durationMinutes = value.round());
                        },
                      ),
                    ),
                    Text('${(durationMinutes / 60).toStringAsFixed(1)}h'),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority Selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Priority:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Priority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: Priority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: PriorityHelper.priorityColors[priority],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(PriorityHelper.priorityLabels[priority]!),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedPriority = value!),
                ),
                const SizedBox(height: 16),

                // Project Selection (drives color)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Project (controls color):', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedProject,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        hint: const Text('Select Project'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('No Project')),
                          ...projects.map(
                            (project) => DropdownMenuItem(
                              value: project,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: projectColors[project],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(project),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => selectedProject = value),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add Project',
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddProjectDialog(context, setState, onAddProject),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Recurring Selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recurring:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurringType>(
                  value: selectedRecurring,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: RecurringType.values
                      .map((recurring) => DropdownMenuItem(
                            value: recurring,
                            child: Text(RecurringHelper.recurringLabels[recurring]!),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRecurring = value!;
                      print("Selected Recurring: $selectedRecurring");
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Color preview (read-only; controlled by project)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text('Event Color (from Project): ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: resolveEventColor(project: selectedProject, priority: selectedPriority),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // if (isEdit)
                EventDialogs.buildActionButton(
                  onPressed: () {
                    Navigator.pop(context);
                    print(event);
                    
                    if (event is ExtendedCalendarEventData && event.recurring != RecurringType.none) {
                      _showDeleteOptionsDialog(context, event as ExtendedCalendarEventData, onDeleteEvent, onDeleteSeries);
                    } else {
                      onDeleteEvent(event!);
                    }
                  },
                  text: "Delete",
                  icon: Icons.delete,
                  color: Colors.red,
                ),

                // else
                //   const SizedBox(width: 100), // Spacer when not editing

                EventDialogs.buildActionButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;

                    final startDateTime = DateTime(
                      eventDate.year,
                      eventDate.month,
                      eventDate.day,
                      startTime.hour,
                      startTime.minute,
                    );
                    final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

                    final computedColor = resolveEventColor(project: selectedProject, priority: selectedPriority);

                    final newEvent = ExtendedCalendarEventData(
                      title: titleController.text,
                      description: descriptionController.text.isEmpty ? null : descriptionController.text,
                      date: DateTime(eventDate.year, eventDate.month, eventDate.day),
                      startTime: startDateTime,
                      endTime: endDateTime,
                      color: computedColor,
                      priority: selectedPriority,
                      project: selectedProject,
                      recurring: isEdit ? (extendedEvent?.recurring ?? RecurringType.none) : selectedRecurring,
                    );

                    onSaveEvent(
                      newEvent, 
                      overrideRecurring: isEdit ? RecurringType.none : null
                    );
                    Navigator.pop(context);
                  },
                  text: isEdit ? "Update" : "Add",
                  icon: isEdit ? Icons.update : Icons.add,
                  color: Colors.blue,
                ),
              ]
            )
          ],
        ),
      ),
    );
  }

  
  static void _showDeleteOptionsDialog(
    BuildContext context,
    ExtendedCalendarEventData event,
    Function(CalendarEventData) onDeleteEvent,
    Function(String) onDeleteSeries, // add here
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Do you want to delete only this event or the entire series?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteEvent(event); // Delete only this one
            },
            child: const Text('Only this event'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteSeries(event.seriesId!); // Call callback for entire series
            },
            child: const Text('Entire series'),
          ),
        ],
      ),
    );
  }

  static void _showAddProjectDialog(BuildContext context, StateSetter parentSetState, Function(String) onAddProject) {
    final projectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Project'),
        content: TextField(
          controller: projectController,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = projectController.text.trim();
              if (name.isNotEmpty) {
                onAddProject(name);
                parentSetState(() {}); // Update parent dialog
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}