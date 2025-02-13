import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/task_controller.dart';
import '../models/task_model.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskModel? task;
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _deadline;
  final List<SubTask> _subTasks = [];

  @override
  void initState() {
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _deadline = widget.task!.deadline;
      _subTasks.addAll(widget.task!.subTasks);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              ListTile(
                title: const Text('Deadline'),
                trailing: _deadline != null
                    ? Text(DateFormat('MMM dd, yyyy HH:mm').format(_deadline!))
                    : const Text('Not set'),
                onTap: () => DatePicker.showDateTimePicker(
                  context,
                  showTitleActions: true,
                  onConfirm: (date) => setState(() => _deadline = date),
                ),
              ),
              const Divider(),
              const Text('Sub Tasks:'),
              ..._subTasks.map((st) => ListTile(
                    title: Text(st.title),
                    trailing: Checkbox(
                      value: st.isCompleted,
                      onChanged: (value) =>
                          setState(() => st.isCompleted = value!),
                    ),
                  )),
              TextButton(
                child: const Text('Add Sub Task'),
                onPressed: () => _addSubTask(),
              ),
              ElevatedButton(
                child: const Text('Save Task'),
                onPressed: () => _saveTask(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSubTask() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController subtaskController = TextEditingController();

        return AlertDialog(
          title: const Text('New Sub Task'),
          content: TextFormField(
            controller: subtaskController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter subtask name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (subtaskController.text.isNotEmpty) {
                  final newSubtask = SubTask(title: subtaskController.text);
                  final controller = Get.find<TaskController>();
                  if (widget.task != null) {
                    await controller.addSubtask(
                        widget.task!.id ?? '', newSubtask);
                  }

                  setState(() => _subTasks.add(newSubtask));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = TaskModel(
        id: widget.task?.id, // Preserve ID only when editing
        title: _titleController.text,
        description: _descController.text,
        deadline: _deadline,
        subTasks: _subTasks,
      );

      print("Saving task: ${task.toJson()}"); // Debug print
      final controller = Get.find<TaskController>();
      if (widget.task == null) {
        await controller.addTask(task); // Add new task (ID auto-generated)
      } else {
        await controller.updateTask(task); // Update existing task (with ID)
      }
      Get.back();
    }
  }
}
