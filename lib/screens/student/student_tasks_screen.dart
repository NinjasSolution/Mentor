import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bgnu_mentor/services/task_service.dart';
import 'package:bgnu_mentor/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bgnu_mentor/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentTasksScreen extends StatefulWidget {
  final bool onlyPending; // Option to filter only pending tasks
  const StudentTasksScreen({super.key, this.onlyPending = false});

  @override
  State<StudentTasksScreen> createState() => _StudentTasksScreenState();
}

class _StudentTasksScreenState extends State<StudentTasksScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TaskService _taskService = TaskService();

  final List<Color> _taskColors = [
    Colors.blue.shade50,
    Colors.teal.shade50,
    Colors.indigo.shade50,
    Colors.deepOrange.shade50,
    Colors.purple.shade50,
  ];

  final List<Color> _accentColors = [
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.purple,
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  String _getTimeRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return "Overdue";
    } else if (difference.inDays == 0) {
      return "Due Today";
    } else if (difference.inDays == 1) {
      return "Due Tomorrow";
    } else {
      return "Due in ${difference.inDays} days";
    }
  }

  void _confirmDelete(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to remove this task from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _taskService.deleteTask(taskId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will delete all assignments from your history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Note: This service call clears tasks for the current student
              // We'll iterate and delete if a specific 'clearAllForStudent' isn't in service
              // But looking at task_service, clearTasks(mentorId, studentId) exists.
              // For student side "Clear History", we might want to clear everything.
              final snapshots = await FirebaseFirestore.instance
                  .collection('tasks')
                  .where('studentId', isEqualTo: currentUserId)
                  .get();
              
              WriteBatch batch = FirebaseFirestore.instance.batch();
              for (var doc in snapshots.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();
              
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(widget.onlyPending ? 'Pending Tasks' : 'My Assignments', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!widget.onlyPending)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              onPressed: _clearAllTasks,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getStudentTasks(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  Text('No tasks available!', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          // Filter logic based on the constructor parameter
          List<TaskModel> tasks = snapshot.data!;
          if (widget.onlyPending) {
            tasks = tasks.where((t) => t.status == 'pending').toList();
          }

          if (tasks.isEmpty) {
            return Center(
              child: Text(
                widget.onlyPending ? 'No pending tasks left! 🎉' : 'No tasks found.',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          tasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(context, task, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, int index) {
    Color bg = _taskColors[index % _taskColors.length];
    Color accent = _accentColors[index % _accentColors.length];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(task.mentorId).get(),
      builder: (context, mentorSnapshot) {
        final mentorName = mentorSnapshot.data?.exists == true ? mentorSnapshot.data!.get('name') : 'Mentor';

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(task.status, accent),
                        Row(
                          children: [
                            Text(
                              DateFormat('dd MMM').format(task.assignedAt),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent.withOpacity(0.5)),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _confirmDelete(task.id),
                              child: Icon(Icons.close_rounded, size: 18, color: Colors.red.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(task.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text('by $mentorName', style: TextStyle(color: accent.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 16),
                    Text(task.description, style: TextStyle(color: Colors.black87.withOpacity(0.7), height: 1.4, fontSize: 14)),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDateRow(
                          task.status == 'pending' ? Icons.timer_outlined : Icons.check_circle_outline, 
                          task.status == 'pending' ? _getTimeRemaining(task.dueDate) : "Completed", 
                          accent
                        ),
                        _buildDateRow(Icons.event_note, DateFormat('dd MMM').format(task.dueDate), accent),
                      ],
                    ),
                    
                    if (task.attachmentUrl != null && task.attachmentUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _launchURL(task.attachmentUrl!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.2))),
                          child: Row(
                            children: [
                              Icon(Icons.description_outlined, color: accent, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(child: Text('Mentor Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              Icon(Icons.download_rounded, size: 20, color: accent),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (task.grade != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: accent, radius: 18, child: const Icon(Icons.grade, color: Colors.white, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GRADE: ${task.grade}', style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 15)),
                                  if (task.feedback != null && task.feedback!.isNotEmpty)
                                    Text(task.feedback!, style: TextStyle(color: accent.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    if (task.status == 'pending')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showSubmitDialog(context, task.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Submit Work', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      )
                    else if (task.status == 'submitted')
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_all, color: accent, size: 20),
                            const SizedBox(width: 8),
                            Text('Submitted', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRow(IconData icon, String text, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  void _showSubmitDialog(BuildContext context, String taskId) {
    final linkController = TextEditingController();
    PlatformFile? pickedFile;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Submit Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (pickedFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(child: Text(pickedFile!.name, style: const TextStyle(fontSize: 14))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => setDialogState(() => pickedFile = null)),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
                    if (result != null) setDialogState(() => pickedFile = result.files.first);
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document (PDF/Image)'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'Drive / GitHub Link',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (linkController.text.isEmpty && pickedFile == null) return;
                    setDialogState(() => isUploading = true);
                    try {
                      String finalLink = linkController.text.trim();
                      if (pickedFile != null) {
                        finalLink = await ApiService().uploadTaskFile(taskId, pickedFile!.bytes!, pickedFile!.name) ?? "";
                      }
                      await TaskService().submitTask(taskId, finalLink);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted successfully!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      setDialogState(() => isUploading = false);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
