import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class TagPicker extends StatefulWidget {
  final List<Tag> allTags;
  final int? selectedTagId;
  final Function(Tag) onChanged;
  final VoidCallback onAddTag;
  final String title;

  const TagPicker({
    Key? key,
    required this.allTags,
    required this.selectedTagId,
    required this.onChanged,
    required this.onAddTag,
    this.title = 'Select Tag',
  }) : super(key: key);

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allTags
        .where((tag) => tag.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onAddTag,
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text('Add new tag',
                      style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const Divider(height: 24, thickness: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final tag = filtered[idx];
                final initials = tag.name.isNotEmpty
                    ? tag.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                    : '?';
                final selected = tag.id == widget.selectedTagId;
                return ListTile(
                  onTap: () {
                    widget.onChanged(tag);
                    Navigator.of(context).pop();
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  title: Text(tag.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                  trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 