import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/task_model.dart';

class TaskController extends GetxController {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final String _baseUrl = 'https://67ab2a7b65ab088ea7e8eeb4.mockapi.io';

  RxList<TaskModel> ongoingTasks = <TaskModel>[].obs;
  RxList<TaskModel> completedTasks = <TaskModel>[].obs;

  @override
  void onInit() {
    _dio.options.headers['Content-Type'] = 'application/json';
    fetchTasks();
    super.onInit();
  }

  Future<void> fetchTasks() async {
    try {
      final response = await _dio.get('$_baseUrl/task');
      final tasks = (response.data as List)
          .map((data) => TaskModel.fromJson(data))
          .toList();

      ongoingTasks.value = tasks.where((t) => !t.isCompleted).toList();
      completedTasks.value = tasks.where((t) => t.isCompleted).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch tasks: $e',
          backgroundColor: Colors.red);
    }
  }

  Future<Either<String, void>> addTask(TaskModel task) async {
    try {
      final response = await _dio.post('$_baseUrl/task', data: task.toJson());
      final newTask = TaskModel.fromJson(response.data);
      for (var subtask in task.subTasks) {
        await _dio.post('$_baseUrl/task/${newTask.id}/subtask',
            data: subtask.toJson());
      }
      final taskWithSubtasks = await _dio.get('$_baseUrl/task/${newTask.id}');
      final updatedTask = TaskModel.fromJson(taskWithSubtasks.data);

      ongoingTasks.add(updatedTask);
      ongoingTasks.refresh();

      return const Right(null);
    } catch (e) {
      return Left('Failed to add task: $e');
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _dio.put('$_baseUrl/task/${task.id}', data: task.toJson());
      await fetchTasks();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update task: $e',
          backgroundColor: Colors.red);
    }
  }

  Future<void> deleteTask(TaskModel task) async {
    try {
      await _dio.delete('$_baseUrl/task/${task.id}');
      ongoingTasks.removeWhere((t) => t.id == task.id);
      completedTasks.removeWhere((t) => t.id == task.id);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete task: $e',
          backgroundColor: Colors.red);
    }
  }

  void toggleSubTask(TaskModel task, SubTask subTask) async {
    subTask.isCompleted = !subTask.isCompleted;

    try {
      await _dio.put(
        '$_baseUrl/task/${task.id}/subtask/${subTask.id}',
        data: {'isCompleted': subTask.isCompleted},
      );
      bool allSubtasksCompleted = task.subTasks.every((st) => st.isCompleted);
      if (allSubtasksCompleted) {
        task.isCompleted = true;
        task.completedAt = DateTime.now();

        await _dio.put(
          '$_baseUrl/task/${task.id}',
          data: {'isCompleted': true},
        );
      } else {
        task.isCompleted = false;
        await _dio.put(
          '$_baseUrl/task/${task.id}',
          data: {'isCompleted': false},
        );
      }

      updateTask(task);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update subtask: $e',
          backgroundColor: Colors.red);
    }
  }

  Future<void> addSubtask(String taskId, SubTask subtask) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/task/$taskId/subtask',
        data: subtask.toJson(),
      );
      final newSubtask = SubTask.fromJson(response.data);
      final task = ongoingTasks.firstWhere((t) => t.id == taskId);
      task.subTasks.add(newSubtask);
      ongoingTasks.refresh();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add subtask: $e',
          backgroundColor: Colors.red);
    }
  }

  void toggleTask(TaskModel task) async {
    task.isCompleted = !task.isCompleted;
    if (task.isCompleted) {
      for (var subTask in task.subTasks) {
        subTask.isCompleted = true;
        await updateSubTask(task.id ?? '', subTask);
      }
    }
    await updateTask(task);
    ongoingTasks.removeWhere((t) => t.id == task.id);
    completedTasks.removeWhere((t) => t.id == task.id);

    if (task.isCompleted) {
      completedTasks.add(task);
    } else {
      ongoingTasks.add(task);
    }
    ongoingTasks.refresh();
    completedTasks.refresh();
  }

  Future<void> updateSubTask(String taskId, SubTask subTask) async {
    try {
      await _dio.put(
        '$_baseUrl/task/$taskId/subtask/${subTask.id}',
        data: subTask.toJson(),
      );
    } catch (e) {
      print("Error updating subtask: $e");
    }
  }
}
