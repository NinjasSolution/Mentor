import 'package:bgnu_mentor/services/course_service.dart';
import 'package:bgnu_mentor/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bgnu_mentor/services/mentor_service.dart';
import 'package:bgnu_mentor/services/task_service.dart';
import 'package:bgnu_mentor/models/task_model.dart';
import 'package:bgnu_mentor/screens/messages/messages_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  final String? filterStatus;
  final String? targetStudentId;
  final bool showAllStudents; 
  
  const UsersScreen({
    super.key, 
    this.filterStatus, 
    this.targetStudentId,
    this.showAllStudents = true,
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final mentorService = MentorService();
  final taskService = TaskService();
  final courseService = CourseService();
  final String currentMentorId = FirebaseAuth.instance.currentUser?.uid ?? '';

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

  bool get _isFilterActive => widget.filterStatus != null;

  @override
  Widget build(BuildContext context) {
    String title = 'My Students';
    if (widget.filterStatus == 'submitted') title = 'Tasks to Review';
    if (widget.filterStatus == 'pending') title = 'Awaiting Submissions';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: mentorService.getMentorshipRequestsForMentor(currentMentorId, status: 'accepted'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No students connected yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final allConnectedStudents = snapshot.data!;

          return StreamBuilder<List<TaskModel>>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('mentorId', isEqualTo: currentMentorId)
                .snapshots()
                .map((snap) => snap.docs.map((doc) => TaskModel.fromMap(doc.data(), doc.id)).toList()),
            builder: (context, tasksSnapshot) {
              final allTasks = tasksSnapshot.data ?? [];
              
              // FILTER LOGIC
              List<Map<String, dynamic>> filteredStudents = [];
              
              if (widget.filterStatus == 'pending') {
                // Students who have AT LEAST ONE 'pending' task
                final studentIdsWithPending = allTasks
                    .where((t) => t.status == 'pending')
                    .map((t) => t.studentId)
                    .toSet();
                filteredStudents = allConnectedStudents
                    .where((s) => studentIdsWithPending.contains(s['studentId']))
                    .toList();
              } else if (widget.filterStatus == 'submitted') {
                // Students who have AT LEAST ONE 'submitted' task
                final studentIdsWithSubmitted = allTasks
                    .where((t) => t.status == 'submitted')
                    .map((t) => t.studentId)
                    .toSet();
                filteredStudents = allConnectedStudents
                    .where((s) => studentIdsWithSubmitted.contains(s['studentId']))
                    .toList();
              } else {
                // Show all students if no filter
                filteredStudents = allConnectedStudents;
              }

              if (filteredStudents.isEmpty && _isFilterActive) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        widget.filterStatus == 'pending' ? 'All students have completed their work!' : 'No tasks to review at the moment.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentCard(context, student, currentMentorId);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, dynamic> student, String mentorId) {
    bool isTarget = widget.targetStudentId == student['studentId'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String studentId = student['studentId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ExpansionTile(
        initiallyExpanded: _isFilterActive || isTarget,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: isDark ? Colors.white : Colors.black,
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue[50],
          backgroundImage: student['studentPic'] != null && student['studentPic'].toString().isNotEmpty 
              ? NetworkImage(student['studentPic']) 
              : null,
          child: (student['studentPic'] == null || student['studentPic'].toString().isEmpty) 
              ? const Icon(Icons.person, color: Colors.blue) 
              : null,
        ),
        title: Text(student['studentName'] ?? 'Unknown Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
        subtitle: _buildStudentMiniProgress(studentId, isDark),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildTrackingDashboard(studentId, isDark),
                const SizedBox(height: 16),
                if (!_isFilterActive)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(receiverId: studentId, receiverName: student['studentName'] ?? 'Student'))),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAssignTaskDialog(context, mentorId, studentId),
                          icon: const Icon(Icons.add_task, size: 18),
                          label: const Text('Assign Task'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700], foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_rounded, size: 20, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Text(_isFilterActive ? 'FILTERED TASKS' : 'TASK HISTORY', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1, fontSize: 12)),
                      ],
                    ),
                    if (!_isFilterActive)
                      TextButton.icon(
                        onPressed: () => _clearTaskHistory(studentId),
                        icon: const Icon(Icons.history, size: 16, color: Colors.red),
                        label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTaskList(mentorId, studentId),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentMiniProgress(String studentId, bool isDark) {
    return StreamBuilder<List<TaskModel>>(
      stream: taskService.getStudentTasks(studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final tasks = snapshot.data!;
        if (tasks.isEmpty) return const Text('No tasks assigned', style: TextStyle(fontSize: 11, color: Colors.grey));
        
        final completed = tasks.where((t) => t.status == 'graded' || t.status == 'submitted').length;
        final percent = completed / tasks.length;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      color: percent == 1.0 ? Colors.green : Colors.blue,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackingDashboard(String studentId, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.blue.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Tasks Done', studentId, isDark, type: 'tasks'),
              _buildVerticalDivider(isDark),
              _buildStatItem('Avg Grade', studentId, isDark, type: 'grades'),
              _buildVerticalDivider(isDark),
              _buildStatItem('Videos Watched', studentId, isDark, type: 'videos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String studentId, bool isDark, {required String type}) {
    return StreamBuilder(
      stream: type == 'videos' 
          ? FirebaseFirestore.instance.collection('video_progress').where('userId', isEqualTo: studentId).snapshots()
          : taskService.getStudentTasks(studentId),
      builder: (context, snapshot) {
        String value = "0";
        if (snapshot.hasData) {
          if (type == 'tasks') {
            final tasks = snapshot.data as List<TaskModel>;
            value = "${tasks.where((t) => t.status == 'graded' || t.status == 'submitted').length}/${tasks.length}";
          } else if (type == 'grades') {
            final tasks = (snapshot.data as List<TaskModel>).where((t) => t.status == 'graded' && t.grade != null).toList();
            if (tasks.isEmpty) {
              value = "N/A";
            } else {
              value = tasks.first.grade!;
            }
          } else if (type == 'videos') {
            final videos = (snapshot.data as QuerySnapshot).docs;
            value = "${videos.length}";
          }
        }

        return Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.blue.shade800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        );
      },
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(height: 30, width: 1, color: isDark ? Colors.white10 : Colors.blue.shade100);
  }

  Widget _buildTaskList(String mentorId, String studentId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<TaskModel>>(
      stream: taskService.getMentorStudentTasks(mentorId, studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        
        List<TaskModel> tasks = snapshot.data ?? [];
        if (widget.filterStatus != null) {
          tasks = tasks.where((t) => t.status == widget.filterStatus).toList();
        }

        if (tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.grey[50], borderRadius: BorderRadius.circular(12)),
            child: Text(_isFilterActive ? 'No tasks matching this status.' : 'No tasks assigned yet.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }

        tasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
        return Column(
          children: List.generate(tasks.length, (index) => _buildTaskItem(context, tasks[index], index)),
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task, int index) {
    bool isSubmitted = task.status == 'submitted';
    bool isGraded = task.status == 'graded';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = isDark ? const Color(0xFF2C2C2C) : _taskColors[index % _taskColors.length];
    Color accent = _accentColors[index % _accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : accent.withOpacity(0.8)))),
              Row(
                children: [
                  _buildStatusBadge(task.status, accent),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => _confirmDeleteTask(task.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: isDark ? Colors.white70 : accent.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('Due: ${DateFormat('dd MMM yyyy').format(task.dueDate)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : accent.withOpacity(0.6))),
            ],
          ),
          
          if (task.attachmentUrl != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _launchURL(context, task.attachmentUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attachment, size: 14, color: accent),
                    const SizedBox(width: 4),
                    Text('Reference File', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],

          if (isSubmitted && task.submissionLink != null) ...[
            const Divider(height: 24),
            Text('STUDENT SUBMISSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : accent.withOpacity(0.7))),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchURL(context, task.submissionLink),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withOpacity(0.2))),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 18, color: accent),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('View Submission', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    Icon(Icons.open_in_new, size: 18, color: accent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showGradeDialog(context, task.id),
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Grade Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (isGraded) ...[
             const Divider(height: 24),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.white, borderRadius: BorderRadius.circular(10)),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('GRADE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                       Text(task.grade ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 16)),
                     ],
                   ),
                   if (task.feedback != null && task.feedback!.isNotEmpty) ...[
                     const SizedBox(height: 6),
                     Text(task.feedback!, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                   ],
                 ],
               ),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDeleteTask(String taskId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This will remove this task assignment permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await taskService.deleteTask(taskId);
    }
  }

  void _clearTaskHistory(String studentId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Task History?'),
        content: const Text('This will delete all tasks between you and this student. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await taskService.clearTasks(currentMentorId, studentId);
    }
  }

  void _showGradeDialog(BuildContext context, String taskId) {
    final gradeController = TextEditingController();
    final feedbackController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Grade Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: gradeController, decoration: InputDecoration(labelText: 'Grade / Marks', hintText: 'e.g. A+, 95/100', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: feedbackController, decoration: InputDecoration(labelText: 'Feedback', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isSaving ? null : () async {
                if (gradeController.text.isEmpty) return;
                setDialogState(() => isSaving = true);
                try {
                  await TaskService().gradeTask(taskId, gradeController.text.trim(), feedbackController.text.trim());
                  if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graded successfully!'), backgroundColor: Colors.green)); }
                } catch (e) { setDialogState(() => isSaving = false); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Submit Grade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    try { if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) { throw 'Could not launch $url'; } } catch (e) { if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } }
  }

  void _showAssignTaskDialog(BuildContext context, String mentorId, String studentId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    PlatformFile? pickedFile;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Assign New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Task Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 16),
                TextField(controller: descController, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                  child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(selectedDate == null ? 'Select Due Date' : DateFormat('dd MMM yyyy').format(selectedDate!)), const Icon(Icons.calendar_month, color: Colors.blue)])),
                ),
                const SizedBox(height: 16),
                if (pickedFile != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.description, color: Colors.blue), const SizedBox(width: 12), Expanded(child: Text(pickedFile!.name, style: const TextStyle(fontSize: 13, color: Colors.black))), IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.black), onPressed: () => setDialogState(() => pickedFile = null))]))
                else OutlinedButton.icon(onPressed: () async { FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true); if (result != null) setDialogState(() => pickedFile = result.files.first); }, icon: const Icon(Icons.upload_file), label: const Text('Attach Reference File'), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isSaving ? null : () async {
                  if (titleController.text.isEmpty || selectedDate == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Date are required.'))); return; }
                  setDialogState(() => isSaving = true);
                  try {
                    String? attachmentUrl;
                    if (pickedFile != null) { attachmentUrl = await ApiService().uploadTaskFile(mentorId + DateTime.now().millisecondsSinceEpoch.toString(), pickedFile!.bytes!, pickedFile!.name); }
                    await TaskService().assignTask(mentorId: mentorId, studentId: studentId, title: titleController.text.trim(), description: descController.text.trim(), dueDate: selectedDate!, attachmentUrl: attachmentUrl);
                    if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task assigned!'), backgroundColor: Colors.green)); }
                  } catch (e) { setDialogState(() => isSaving = false); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
                }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
