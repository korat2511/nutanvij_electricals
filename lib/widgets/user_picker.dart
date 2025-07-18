import 'package:flutter/material.dart';
import '../models/site.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class UserPicker extends StatefulWidget {
  final List<UserInSite> allUsers;
  final List<UserInSite> selectedUsers;
  final Function(List<UserInSite>) onChanged;
  final bool multiSelect;
  final String title;

  const UserPicker({
    Key? key,
    required this.allUsers,
    required this.selectedUsers,
    required this.onChanged,
    this.multiSelect = true,
    this.title = 'Select Users',
  }) : super(key: key);

  @override
  State<UserPicker> createState() => _UserPickerState();
}

class _UserPickerState extends State<UserPicker> {
  late List<UserInSite> _tempSelected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = List<UserInSite>.from(widget.selectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allUsers
        .where((user) => user.name.toLowerCase().contains(_search.toLowerCase()))
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
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final user = filtered[idx];
                final selected = _tempSelected.any((u) => u.id == user.id);
                return ListTile(
                  onTap: () {
                    setState(() {
                      if (widget.multiSelect) {
                        if (selected) {
                          _tempSelected.removeWhere((u) => u.id == user.id);
                        } else {
                          _tempSelected.add(user);
                        }
                      } else {
                        _tempSelected = [user];
                      }
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  title: Text(user.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                  trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.onChanged(List<UserInSite>.from(_tempSelected));
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 