import 'package:flutter/material.dart';
import '../../models/contractor.dart';

class ContractorBottomSheet extends StatefulWidget {
  final List<Contractor> contractors;
  final int? selectedId;

  const ContractorBottomSheet({
    Key? key,
    required this.contractors,
    this.selectedId,
  }) : super(key: key);

  @override
  State<ContractorBottomSheet> createState() => _ContractorBottomSheetState();
}

class _ContractorBottomSheetState extends State<ContractorBottomSheet> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.contractors
        .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Select Contractor",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Contractor",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          const SizedBox(height: 8),
          // Contractor list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final contractor = filtered[idx];
                return ListTile(
                  title: Text(contractor.name),
                  subtitle: Text(contractor.mobile),
                  trailing: contractor.id == widget.selectedId
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => Navigator.pop(context, contractor.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
