import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'services/google_calendar_service.dart';

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
  final TextEditingController _dateController = TextEditingController();
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
      if (createdAt is Timestamp) {
        _selectedDate = createdAt.toDate();
      } else if (createdAt is DateTime) {
        _selectedDate = createdAt;
      }

      if (_selectedDate != null) {
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || currentUser == null) return;
    setState(() => _loading = true);

    // Logika penyimpanan data ke Firestore dan Google Calendar
    String? eventId;
    try {
      GoogleSignInAccount? googleUser;
      if (currentUser?.providerData.any((p) => p.providerId == 'google.com') ??
          false) {
        googleUser = await _googleSignIn.signInSilently();
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
        'day': _selectedDate?.day,
        'month': _selectedDate?.month,
        'year': _selectedDate?.year,
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
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan tugas: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF86B6F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 10,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.isEdit ? 'Edit Tugas' : 'Tugas Baru',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 30.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Judul wajib diisi'
                                  : null,
                      decoration: _buildInputDecoration(
                        label: "Judul Tugas",
                        primaryColor: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: _buildInputDecoration(
                        label: "Deskripsi (Opsional)",
                        primaryColor: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: _buildInputDecoration(
                        label: "Tanggal Tenggat (Opsional)",
                        primaryColor: primaryColor,
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  widget.isEdit
                                      ? 'Simpan Perubahan'
                                      : 'Tambah Tugas',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required Color primaryColor,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      suffixIcon:
          suffixIcon != null ? Icon(suffixIcon, color: primaryColor) : null,
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
