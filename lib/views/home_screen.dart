import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../controllers/task_controller.dart';
import '../models/task_model.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TaskController>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo App'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.fetchTasks,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Get.to(() => const AddTaskScreen()),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: TabBarView(
          children: [
            _buildTaskList(controller.ongoingTasks),
            _buildTaskList(controller.completedTasks, isCompleted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(RxList<TaskModel> tasks, {bool isCompleted = false}) {
    return Obx(() => ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
        ));
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TaskController>();

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Row(
          children: [
            if (task.isOverdue) const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(task.title)),
            if (task.subTasks.isNotEmpty)
              LinearPercentIndicator(
                width: 100,
                lineHeight: 8,
                percent: task.isCompleted
                    ? 1.0
                    : task.progress, // ✅ Show 100% if completed
                progressColor: Colors.green,
              ),
          ],
        ),
        subtitle: task.deadline != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.description),
                  Text(
                      'Deadline: ${DateFormat('MMM dd, yyyy HH:mm').format(task.deadline!)}'),
                ],
              )
            : null,
        trailing: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            controller.toggleTask(task);
          },
        ),
        children: [
          if (task.subTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: task.subTasks
                    .map((subTask) => ListTile(
                          title: Text(subTask.title),
                          trailing: Checkbox(
                            value: subTask.isCompleted,
                            onChanged: task.isCompleted
                                ? null
                                : (value) =>
                                    controller.toggleSubTask(task, subTask),
                          ),
                        ))
                    .toList(),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: task.isCompleted
                    ? null
                    : () => Get.to(() => AddTaskScreen(task: task)),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed:
                    task.isCompleted ? null : () => controller.deleteTask(task),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
