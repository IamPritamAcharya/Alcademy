import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import '../models/note_branch.dart';
import '../models/note_year.dart';

/// Shared branch browsing and note selection for onboarding and Change year.
class NotesShelfPicker extends StatefulWidget {
  final List<NoteYear> years;
  final String? preferredBranch;
  final String? selectedUrl;
  final ValueChanged<NoteYear> onSelected;
  final Future<void> Function()? onRefresh;
  const NotesShelfPicker({
    super.key,
    required this.years,
    this.preferredBranch,
    this.selectedUrl,
    required this.onSelected,
    this.onRefresh,
  });

  @override
  State<NotesShelfPicker> createState() => _NotesShelfPickerState();
}

class _NotesShelfPickerState extends State<NotesShelfPicker> {
  NoteBranch? _branch;
  @override
  void initState() {
    super.initState();
    _branch = NoteBranch.fromProfile(widget.preferredBranch);
  }

  @override
  Widget build(BuildContext context) {
    final visible = NoteBranch.filter(widget.years, _branch);
    final current = widget.years
        .where((year) => year.url == widget.selectedUrl)
        .firstOrNull;
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const Text('YOUR STUDY SHELF', style: AppStyle.eyebrow),
        const SizedBox(height: 14),
        Text(
          _branch?.label ?? 'All branches',
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.bold,
            color: AppStyle.text,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Start with your branch. Explore another whenever you like.',
          style: TextStyle(color: AppStyle.muted, height: 1.5),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<NoteBranch?>(
          key: ValueKey(_branch),
          initialValue: _branch,
          isExpanded: true,
          dropdownColor: AppStyle.surface,
          decoration: const InputDecoration(
            labelText: 'Browse branch',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<NoteBranch?>(
              value: null,
              child: Text('All branches'),
            ),
            for (final branch in NoteBranch.values)
              DropdownMenuItem<NoteBranch?>(
                value: branch,
                child: Text(
                  '${branch.code} · ${branch.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _branch = value),
        ),
        if (current != null) ...[
          const SizedBox(height: 16),
          Text(
            'Current shelf: ${current.name}',
            style: const TextStyle(color: AppStyle.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 26),
        if (_branch != null &&
            !visible.any((year) => NoteBranch.ofYear(year) == _branch))
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'No ${_branch!.code} semester notes yet. You can choose common first-year notes or browse another branch.',
              style: const TextStyle(color: AppStyle.muted, height: 1.5),
            ),
          ),
        if (visible.isEmpty)
          const Text(
            'No notes available yet.',
            style: TextStyle(color: AppStyle.muted),
          ),
        for (final year in visible)
          _NoteShelfRow(
            year: year,
            selected: year.url == widget.selectedUrl,
            onTap: () => widget.onSelected(year),
          ),
      ],
    );
    return widget.onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: widget.onRefresh!, child: list);
  }
}

class _NoteShelfRow extends StatelessWidget {
  final NoteYear year;
  final bool selected;
  final VoidCallback onTap;
  const _NoteShelfRow({
    required this.year,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppStyle.rule)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (selected ? AppStyle.accent : AppStyle.paper)
                      .withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  NoteBranch.isCommon(year)
                      ? Icons.school_outlined
                      : Icons.auto_stories_outlined,
                  color: selected ? AppStyle.accent : AppStyle.paper,
                  size: 21,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.name,
                      style: const TextStyle(
                        color: AppStyle.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      selected
                          ? 'Selected shelf'
                          : NoteBranch.isCommon(year)
                          ? 'Common to every branch'
                          : NoteBranch.ofYear(year)?.code ?? 'Study resources',
                      style: TextStyle(
                        color: selected ? AppStyle.accent : AppStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? AppStyle.accent : AppStyle.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<NoteYear?> showNotesShelfPicker(
  BuildContext context, {
  required List<NoteYear> years,
  String? preferredBranch,
  String? selectedUrl,
}) => showModalBottomSheet<NoteYear>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppStyle.background,
  showDragHandle: true,
  builder: (context) => FractionallySizedBox(
    heightFactor: .88,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Choose your notes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close notes picker',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: NotesShelfPicker(
            years: years,
            preferredBranch: preferredBranch,
            selectedUrl: selectedUrl,
            onSelected: (year) => Navigator.pop(context, year),
          ),
        ),
      ],
    ),
  ),
);
