import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/google_calendar_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AddEditTaskPage extends StatefulWidget {
  final Map<String, dynamic>? task;
  final String? taskId;
  final bool isEdit;
  const AddEditTaskPage({
    super.key,
    this.task,
    this.taskId,
    this.isEdit = false,
  });

  @override
  State<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends State<AddEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/calendar'],
  );
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.task != null) {
      _titleController.text = widget.task!['task'] ?? '';
      _descController.text = widget.task!['description'] ?? '';
      final createdAt = widget.task!['createdAt'];
      DateTime? date;
      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      } else if (createdAt is DateTime) {
        date = createdAt;
      }
      if (date != null) {
        _selectedDate = date;
      } else {
        _selectedDate = null;
      }
    } else {
      _selectedDate = null;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;
    setState(() => _loading = true);
    int? day, month, year;
    if (_selectedDate != null) {
      day = _selectedDate!.day;
      month = _selectedDate!.month;
      year = _selectedDate!.year;
    }
    String? eventId;
    try {
      // Hanya lakukan sinkronisasi Google Calendar jika user login Google
      GoogleSignInAccount? googleUser;
      // Cek apakah user login dengan Google
      if (currentUser?.providerData.any((p) => p.providerId == 'google.com') ==
          true) {
        googleUser = await _googleSignIn.signInSilently();
        googleUser ??= await _googleSignIn.signIn();
      }
      if (googleUser != null && _selectedDate != null) {
        if (widget.isEdit &&
            widget.task != null &&
            widget.task!['eventId'] != null) {
          await _calendarService.updateEvent(
            widget.task!['eventId'],
            _titleController.text.trim(),
            _selectedDate!,
            googleUser,
            description: _descController.text.trim(),
          );
          eventId = widget.task!['eventId'];
        } else {
          eventId = await _calendarService.insertEvent(
            _titleController.text.trim(),
            _selectedDate!,
            googleUser,
            description: _descController.text.trim(),
          );
        }
      }
      final data = {
        'task': _titleController.text.trim(),
        'isDone': widget.isEdit ? widget.task!['isDone'] : false,
        'description': _descController.text.trim(),
        'createdAt': _selectedDate,
        'day': day,
        'month': month,
        'year': year,
        'eventId': eventId,
      };
      if (widget.isEdit && widget.taskId != null) {
        await FirebaseFirestore.instance
            .collection('todoapp')
            .doc(currentUser!.uid)
            .collection('todos')
            .doc(widget.taskId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('todoapp')
            .doc(currentUser!.uid)
            .collection('todos')
            .add(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan task: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Task' : 'Tambah Task'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Judul',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _titleController,
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Judul wajib diisi'
                            : null,
                decoration: const InputDecoration(
                  hintText: 'Masukkan judul task',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Deskripsi (opsional)',
                ),
              ),
              const SizedBox(height: 16),
              // Tanggal
              const Text(
                'Tanggal (opsional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Hari'),
                          controller: TextEditingController(
                            text:
                                _selectedDate != null
                                    ? _selectedDate!.day.toString()
                                    : '',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Bulan'),
                          controller: TextEditingController(
                            text:
                                _selectedDate != null
                                    ? [
                                      'Januari',
                                      'Februari',
                                      'Maret',
                                      'April',
                                      'Mei',
                                      'Juni',
                                      'Juli',
                                      'Agustus',
                                      'September',
                                      'Oktober',
                                      'November',
                                      'Desember',
                                    ][_selectedDate!.month - 1]
                                    : '',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Tahun'),
                          controller: TextEditingController(
                            text:
                                _selectedDate != null
                                    ? _selectedDate!.year.toString()
                                    : '',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveTask,
                  child:
                      _loading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            widget.isEdit ? 'Simpan Perubahan' : 'Tambah Task',
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
