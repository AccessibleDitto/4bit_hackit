import 'package:flutter/material.dart';
import '../models/task_models.dart';

class TaskFormDialog {
  static void showTaskDialog(
    BuildContext context, {
    Task? existingTask,
    required Function(Task) onSaveTask,
  }) {
    showDialog(
      context: context,
      builder: (context) => TaskFormWidget(
        existingTask: existingTask,
        onSaveTask: onSaveTask,
      ),
    );
  }
}

class TaskFormWidget extends StatefulWidget {
  final Task? existingTask;
  final Function(Task) onSaveTask;
  
  const TaskFormWidget({
    Key? key,
    this.existingTask,
    required this.onSaveTask,
  }) : super(key: key);
  
  @override
  _TaskFormWidgetState createState() => _TaskFormWidgetState();
}

class _TaskFormWidgetState extends State<TaskFormWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedTimeController;
  Priority _priority = Priority.medium;
  EnergyLevel _energyRequired = EnergyLevel.medium;
  TimePreference _timePreference = TimePreference.flexible;
  DateTime? _dueDate;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingTask?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingTask?.description ?? '',
    );
    _estimatedTimeController = TextEditingController(
      text: widget.existingTask?.estimatedTime.toString() ?? '1.0',
    );
    
    if (widget.existingTask != null) {
      _priority = widget.existingTask!.priority;
      _energyRequired = widget.existingTask!.energyRequired;
      _timePreference = widget.existingTask!.timePreference;
      _dueDate = widget.existingTask!.dueDate;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTask == null ? 'Add Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _estimatedTimeController,
              decoration: const InputDecoration(labelText: 'Estimated Time (hours)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Priority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: Priority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EnergyLevel>(
              value: _energyRequired,
              decoration: const InputDecoration(labelText: 'Energy Required'),
              items: EnergyLevel.values.map((energy) {
                return DropdownMenuItem(
                  value: energy,
                  child: Text(energy.displayName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _energyRequired = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TimePreference>(
              value: _timePreference,
              decoration: const InputDecoration(labelText: 'Time Preference'),
              items: TimePreference.values.map((pref) {
                return DropdownMenuItem(
                  value: pref,
                  child: Text(pref.name.toLowerCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _timePreference = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(_dueDate?.toString().split(' ')[0] ?? 'No due date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            
            final task = Task(
              id: widget.existingTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty 
                  ? null 
                  : _descriptionController.text.trim(),
              estimatedTime: double.tryParse(_estimatedTimeController.text) ?? 1.0,
              priority: _priority,
              energyRequired: _energyRequired,
              timePreference: _timePreference,
              dueDate: _dueDate,
              createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            widget.onSaveTask(task);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }
}