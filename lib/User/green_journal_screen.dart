import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/green_journal_entry.dart';
import '../services/journal_db_helper.dart';

class GreenJournalScreen extends StatefulWidget {
  const GreenJournalScreen({super.key});

  @override
  State<GreenJournalScreen> createState() => _GreenJournalScreenState();
}

class _GreenJournalScreenState extends State<GreenJournalScreen> {
  static const Color _primary = Color(0xFF2D7A4F);
  static const Color _ink = Color(0xFF1A4731);
  static const Color _bg = Color(0xFFF0F6F2);

  final _db = JournalDbHelper.instance;

  bool _isLoading = true;
  List<GreenJournalEntry> _entries = [];
  int _totalEntries = 0;
  int _thisWeekEntries = 0;
  int _totalEcoPoints = 0;

  final List<String> _categories = const [
    'Daily Habit',
    'Recycling',
    'Transport',
    'Energy Saving',
    'Waste Reduction',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _db.getAllEntries();
      final totalEntries = await _db.getTotalEntriesCount();
      final thisWeekEntries = await _db.getThisWeekEntriesCount();
      final totalEcoPoints = await _db.getTotalEcoPoints();

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _totalEntries = totalEntries;
        _thisWeekEntries = thisWeekEntries;
        _totalEcoPoints = totalEcoPoints;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Failed to load journal entries.', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        backgroundColor:
        isError ? const Color(0xFFE05454) : const Color(0xFF3DAB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Future<void> _openEntrySheet({GreenJournalEntry? editing}) async {
    final titleController =
    TextEditingController(text: editing?.title ?? '');
    final noteController =
    TextEditingController(text: editing?.note ?? '');
    final pointsController = TextEditingController(
      text: editing?.ecoPoints.toString() ?? '5',
    );

    String selectedCategory = editing?.category ?? _categories.first;
    DateTime selectedDate =
    editing != null ? DateTime.parse(editing.entryDate) : DateTime.now();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing == null ? 'Add Journal Entry' : 'Edit Journal Entry',
                        style: GoogleFonts.dmSans(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildInputField(
                        controller: titleController,
                        label: 'Title',
                        hint: 'e.g. Used reusable bottle',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Category',
                        style: GoogleFonts.dmSans(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedCategory = value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF7F9F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInputField(
                        controller: noteController,
                        label: 'Note',
                        hint: 'Write a short eco-friendly activity note',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      _buildInputField(
                        controller: pointsController,
                        label: 'Eco Points',
                        hint: '5',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Entry Date',
                        style: GoogleFonts.dmSans(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9F8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _formatDate(selectedDate.toIso8601String()),
                            style: GoogleFonts.dmSans(color: _ink),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _ink,
                                side: const BorderSide(color: Color(0xFFD4E6D8)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true) return;

    final title = titleController.text.trim();
    final note = noteController.text.trim();
    final ecoPoints = int.tryParse(pointsController.text.trim()) ?? 0;

    if (title.isEmpty || note.isEmpty) {
      _showSnack('Title and note cannot be empty.', isError: true);
      return;
    }

    final entry = GreenJournalEntry(
      id: editing?.id,
      title: title,
      category: selectedCategory,
      note: note,
      ecoPoints: ecoPoints,
      entryDate: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      ).toIso8601String(),
      createdAt: editing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    try {
      if (editing == null) {
        await _db.insertEntry(entry);
        _showSnack('Journal entry added.', isError: false);
      } else {
        await _db.updateEntry(entry);
        _showSnack('Journal entry updated.', isError: false);
      }
      await _loadEntries();
    } catch (_) {
      _showSnack('Failed to save entry.', isError: true);
    }
  }

  Future<void> _deleteEntry(GreenJournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Entry',
            style: GoogleFonts.dmSans(
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this journal entry?',
            style: GoogleFonts.dmSans(color: Colors.grey.shade600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE05454),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || entry.id == null) return;

    try {
      await _db.deleteEntry(entry.id!);
      _showSnack('Journal entry deleted.', isError: false);
      await _loadEntries();
    } catch (_) {
      _showSnack('Failed to delete entry.', isError: true);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: _ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F9F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(GreenJournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: GoogleFonts.dmSans(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.category_outlined,
                entry.category,
                const Color(0xFFE8F5EE),
                _primary,
              ),
              _chip(
                Icons.eco_outlined,
                '+${entry.ecoPoints} pts',
                const Color(0xFFE8F0FA),
                const Color(0xFF4A90D9),
              ),
              _chip(
                Icons.calendar_today_outlined,
                _formatDate(entry.entryDate),
                const Color(0xFFF7F9F8),
                _ink,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.note,
            style: GoogleFonts.dmSans(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEntrySheet(editing: entry),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: Color(0xFFD4E6D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteEntry(entry),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE05454),
                    side: const BorderSide(color: Color(0xFFE05454)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntrySheet(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: _primary),
      )
          : RefreshIndicator(
        onRefresh: _loadEntries,
        color: _primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A4731), Color(0xFF2D7A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Green Journal',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 38, height: 38),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7EEDB0),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF1A4731),
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Green Journal',
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track your daily eco-friendly habits offline.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _statCard(
                      title: 'Total Entries',
                      value: _totalEntries.toString(),
                      icon: Icons.note_alt_rounded,
                      color: _primary,
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      title: 'This Week',
                      value: _thisWeekEntries.toString(),
                      icon: Icons.date_range_rounded,
                      color: const Color(0xFF4A90D9),
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      title: 'Total Eco Points',
                      value: _totalEcoPoints.toString(),
                      icon: Icons.eco_rounded,
                      color: const Color(0xFF3DAB6A),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Journal Entries',
                      style: GoogleFonts.dmSans(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'No journal entries yet. Tap "Add Entry" to start.',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ..._entries.map(_entryCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}